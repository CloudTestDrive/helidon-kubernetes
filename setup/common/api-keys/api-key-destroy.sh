#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one arguments, the tracking name for the key (e.g. devops or"
  echo "capi etc.)"
  exit 1
fi
KEY_NAME=$1

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z "$USER_OCID" ]
then
  echo '$SCRIPT_NAME No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
  exit 1
fi

if [ -z $USER_INITIALS ]
then
  echo "$SCRIPT_NAME Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

API_KEY_REUSED_NAME=`bash ./get-key-reused-var-name.sh "$KEY_NAME" "$USER_INITIALS"`
API_KEY_FINGERPRINT_NAME=`bash ./get-key-fingerprint-var-name.sh "$KEY_NAME" "$USER_INITIALS"`
# do the redirect trick
API_KEY_REUSED="${!API_KEY_REUSED_NAME}"
API_KEY_FINGERPRINT="${!API_KEY_FINGERPRINT_NAME}"

if [ -z "$API_KEY_REUSED" ]
then
  echo "No saved API key information for key $KEY_NAME, perhaps it's already been removed ? Cannot safely proceed."
  exit 0
else
  echo "API key reuse info for key $KEY_NAME found, proceeding"
fi

if [ "$API_KEY_REUSED" = true ]
then
  echo "API Key was not created by this script, cannot continue."
  bash ../delete-from-saved-settings.sh $API_KEY_FINGERPRINT_NAME
  bash ../delete-from-saved-settings.sh $API_KEY_REUSED_NAME
  exit 0
else
  echo "API key setup by these scripts, proceeding"
fi

if [ -z "$API_KEY_FINGERPRINT" ]
then
  echo "No saved API key fingerprint, cannot proceed."
  exit 4
else
  echo "Found fingerprint for API Key $KEY_NAME"
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
echo "Deleting API key"

oci iam user api-key delete --user-id $USER_OCID --fingerprint $API_KEY_FINGERPRINT --force --region $OCI_HOME_REGION

bash ../delete-from-saved-settings.sh $API_KEY_FINGERPRINT_NAME
bash ../delete-from-saved-settings.sh $API_KEY_REUSED_NAME