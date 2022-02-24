#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

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
  echo "No saved API key information, cannot safely proceed."
  exit 2
else
  echo "API key was created by these scripts, proceeding"
fi
if [ -z $API_KEY_FINGERPRINT ]
then
  echo "No saved API key fingerprint, cannot proceed."
  exit 2
else
  echo "Found API Key fingerprint"
fi

echo "Deleting API key"

oci iam user api-key delete --user-id $USER_OCID --fingerprint $API_KEY_FINGERPRINT --force

bash ../delete-from-saved-settings.sh API_KEY_FINGERPRINT
bash ../delete-from-saved-settings.sh API_KEY_REUSED