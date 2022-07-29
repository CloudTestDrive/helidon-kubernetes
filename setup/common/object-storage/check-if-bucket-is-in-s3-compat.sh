#!/bin/bash -f

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME Missing arguments you must provide:"
  echo "  1st argument - name of the bucket to check - this must be upper case A-Z only and can only use _ to separate words"
fi
BUCKET_NAME=$1

BUCKET_JSON=`oci os bucket get --bucket-name $BUCKET_NAME 2>&1 | grep -v '^ServiceError:$' `
# see if it exists
BUCKET_OCID=`echo "$BUCKET_JSON" | jq -r '.data.id'`
if [ -z "$BUCKET_OCID" ]
then
  BUCKET_OCID="null"
fi
if [ "$BUCKET_OCID" = "null" ]
then
  echo "Bucket $BUCKET_NAME not found"
  exit -1
fi

OOSS_NAMESPACE=`oci os  ns get | jq -r ".data"`
echo "Bucket $BUCKET_NAME found, getting Object storage S3 compat compartment to compare"
S3_COMPAT_OCID=`oci os  ns get-metadata  --namespace-name $OOSS_NAMESPACE | jq -r '.data."default-s3-compartment-id"'`
S3_COMPARTMENT_NAME=`oci iam compartment get --compartment-id $S3_COMPAT_OCID | jq -r ".data.name"`

BUCKET_COMPARTMENT_OCID=`echo "$BUCKET_JSON" | jq -r '.data."compartment-id"'`

if [ "$S3_COMPAT_OCID" = "$BUCKET_COMPARTMENT_OCID" ]
then
  echo "Bucket $BUCKET_NAME is in the S3 compatibility compartment $S3_COMPARTMENT_NAME"
  exit 0
else
  echo "Bucket $BUCKET_NAME is not in the S3 compatibility compartment $S3_COMPARTMENT_NAME"
  exit 1
fi