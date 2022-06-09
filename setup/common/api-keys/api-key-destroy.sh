#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z "$USER_OCID" ]
then
  echo 'No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
  exit 1
fi
if [ -z "$API_KEY_REUSED" ]
then
  echo "No saved API key information, perhaps it's already been removed ? Cannot safely proceed."
  exit 0
else
  echo "API key reuse info found, proceeding"
fi

if [ "$API_KEY_REUSED" = true ]
then
  echo "API Key was not created by this script, cannot continue."
  bash ../delete-from-saved-settings.sh API_KEY_FINGERPRINT
  bash ../delete-from-saved-settings.sh API_KEY_REUSED
  exit 0
else
  echo "API key reuse info found, proceeding"
fi

if [ -z "$API_KEY_FINGERPRINT" ]
then
  echo "No saved API key fingerprint, cannot proceed."
  exit 4
else
  echo "Found API Key fingerprint"
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
echo "Deleting API key"

oci iam user api-key delete --user-id $USER_OCID --fingerprint $API_KEY_FINGERPRINT --force --region $OCI_HOME_REGION

bash ../delete-from-saved-settings.sh API_KEY_FINGERPRINT
bash ../delete-from-saved-settings.sh API_KEY_REUSED