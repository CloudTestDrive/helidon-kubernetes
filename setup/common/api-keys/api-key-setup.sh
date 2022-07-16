#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings
if [ $# -lt 2 ]
then
  echo "The upload-api-key.sh script requires two arguments, the tracking name for the key (e.g. devops or"
  echo "capi) and then file name of the public key to upload, this must be in PEM format."
  exit 1
fi
KEY_NAME=$1
PUBLIC_KEY_FILE=$2

if [ -f $PUBLIC_KEY_FILE ]
then
  echo "Located public key file"
else 
  echo "Unable to locate $PUBLIC_KEY_FILE, cannot continue"
  exit 4
fi

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $USER_OCID ]
then
  echo 'No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
  exit 1
fi

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

API_KEY_REUSED_NAME=`bash ./get-key-reused-var-name.sh "$KEY_NAME" "$USER_INITIALS"`
API_KEY_FINGERPRINT_NAME=`bash ./get-key-fingerprint-var-name.sh "$KEY_NAME" "$USER_INITIALS"`
# do the redirect trick
API_KEY_REUSED="${!API_KEY_REUSED_NAME}"
if [ -z $API_KEY_REUSED ]
then
  echo "No saved API key information for $KEY_NAME, continuing."
else
  echo "Your API key for $KEY_NAME has already been set using these scripts"
  exit 0
fi

API_KEY_COUNT=`oci iam user api-key list --user-id $USER_OCID --all | jq -e '.data | length'`

if [ -z $AUTH_TOKEN_COUNT ]
then
  AUTH_TOKEN_COUNT=0
fi

if [ $AUTH_TOKEN_COUNT -eq 3 ]
then
  echo "You are already at the maximum number of api keys"
  exit 3
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

# OK, let's upload the provided key

RESP=`oci iam user api-key upload --user-id $USER_OCID --key-file $PUBLIC_KEY_FILE --region $OCI_HOME_REGION 2>&1`

# Look for an error
ERROR_MESSAGE=`echo $RESP | sed -e 's/ServiceError: //' | jq -r '.message'`

if [ "$ERROR_MESSAGE" = "null" ]
then
  API_KEY_FINGERPRINT=`echo $RESP | jq -r '.data.fingerprint'`
  echo "$API_KEY_FINGERPRINT_NAME=$API_KEY_FINGERPRINT" >> $SETTINGS
  echo "$API_KEY_REUSED_NAME=false" >> $SETTINGS
  echo "Uploaded key with fingerprint $API_KEY_FINGERPRINT"
  exit 0
else
  ERROR_CODE=`echo $RESP | sed -e 's/ServiceError: //' | jq -r '.code'`
  if [ "$ERROR_CODE" = "KeyAlreadyExists" ]
  then
    echo "The key has already been uploaded, it will be reused"
    echo "API_KEY_REUSED=true" >> $SETTINGS
    exit 100
  fi
  echo "Problem uploading the PEM file, the error message was"
  echo $ERROR_MESSAGE
  exit 10
fi
