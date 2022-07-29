#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME Missing arguments you must provide:"
  echo "  1st argument - name of the bucket to create - this must meet the object storage bucket names restrictions"
  echo "Optionally"
  echo "  2nd argument - the storage tier to use - will default to standard"
  echo "  3rd argument - the OCID of the compartment to create the cluster in, if not proviced will devailt to the cluster being used by the rest of the labs"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
BUCKET_NAME=$1

STORAGE_TIER=standard
if [ $# -ge 2 ]
then
  STORAGE_TIER="$2"
  echo "$SCRIPT_NAME Using provided storage tier of $STORAGE_TIER"
else
  echo "$SCRIPT_NAME Using default storage tier of $STORAGE_TIER"
fi
if [ $# -ge 3 ]
then
  STORAGE_COMPARTMENT_OCID="$3"
  echo "$SCRIPT_NAME Operating on provided storage comparement OCID $STORAGE_COMPARTMENT_OCID"
else
  if [ -z "$COMPARTMENT_OCID" ]
  then
    echo "You need to provide a compartment to create the storage in, COMPARTMENT_OCID is not set, have yu run the compartment-setup script ?"
    exit 1 ;
  else
    STORAGE_COMPARTMENT_OCID="$COMPARTMENT_OCID"
  echo "$SCRIPT_NAME Operating on default storage comparement OCID $STORAGE_COMPARTMENT_OCID"
  fi
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

# check to see if we've created this bucket in the past
BUCKET_REUSED_NAME=`bash ../settings/to-valid-name.sh "$BUCKET_NAME"_REUSED`
BUCKET_REUSED="${!BUCKET_REUSED_NAME}"
if [ -z "$BUCKET_REUSED" ]
then
  echo "Bucket $BUCKET_NAME not created by these scripts - continuing"
else
  echo "Bucket $BUCKET_NAME already created by these scripts - will exit"
  exit 0
fi
BUCKET_JSON=`oci os bucket get --bucket-name $BUCKET_NAME 2>&1 | grep -v '^ServiceError:$' `
# see if it exists
BUCKET_OCID=`echo "$BUCKET_JSON" | jq -r '.data.id'`
if [ -z "$BUCKET_OCID" ]
then
  BUCKET_OCID="null"
fi


BUCKET_OCID_NAME=`bash ../settings/to-valid-name.sh "$BUCKET_NAME"_OCID`
bash ../delete-from-saved-settings.sh $BUCKET_OCID_NAME
bash ../delete-from-saved-settings.sh $BUCKET_REUSED_NAME

if [ "$BUCKET_OCID" = "null" ]
then
  echo "Bucket $BUCKET_NAME not found, creating"
  BUCKET_OCID=`oci os bucket create --compartment-id $S3_COMPAT_OCID  --name $BUCKET_NAME --storage-tier $STORAGE_TIER | jq -r '.data.id'`
  echo "$BUCKET_OCID_NAME=BUCKET_OCID" >> $SETTINGS
  echo "$BUCKET_REUSED_NAME=false" >> $SETTINGS
else
  echo "Bucket $BUCKET_NAME already exists, will reuse"
  echo "$BUCKET_OCID=BUCKET_OCID" >> $SETTINGS
  echo "$BUCKET_REUSED_NAME=true" >> $SETTINGS
fi