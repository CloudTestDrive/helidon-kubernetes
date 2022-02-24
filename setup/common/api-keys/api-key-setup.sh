#!/bin/bash -f
if [ $# -lt 1 ]
then
  echo "The upload-api-key.sh script requires one argument, the file name of the public key to upload, this must be in PEM format"
  exit 1
fi

PUBLIC_KEY_FILE=$1

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
    echo "No existing settings cannot contiue"
    exit 10
fi

if [ -z $USER_OCID ]
then
  echo 'No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
  exit 1
fi

if [ -z $API_KEY_REUSED ]
then
  echo "No saved API key information, continuing."
else
  echo "Your API key has already been set using these scripts"
  exit 2
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

# OK, let's upload the provided key

RESP=`oci iam user api-key upload --user-id $USER_OCID --key-file $PUBLIC_KEY_FILE 2>&1`

# Look for an error
ERROR_MESSAGE=`echo $RESP | sed -e 's/ServiceError: //' | jq -r '.message'`

if [ $ERROR_MESSAGE = "null" ]
then
  API_KEY_FINGERPRINT=`echo $RESP | jq -r '.data.fingerprint'`
  echo API_KEY_FINGERPRINT=$API_KEY_FINGERPRINT >> $SETTINGS
  echo API_KEY_REUSED=false >> $SETTINGS
  echo "Uploaded key with fingerprint $API_KEY_FINGERPRINT"
  exit 0
else
  ERROR_CODE=`echo $RESP | sed -e 's/ServiceError: //' | jq -r '.code'`
  if [ "$ERROR_CODE" = "KeyAlreadyExists" ]
  then
    echo "The key has already been uploaded, it will be reused"
    echo API_KEY_REUSED=true >> $SETTINGS
    exit 100
  fi
  echo "Problem uploading the PEM file, the error message was"
  echo $ERROR_MESSAGE
  exit 10
fi
