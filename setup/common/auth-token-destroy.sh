#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z $AUTH_TOKEN_REUSED ]
then
  echo "$SCRIPT_NAME No reuse information for token cannot safely continue, , perhaps it's already been removed ? You will have to destroy it manually"
  exit 0
fi

if [ $AUTH_TOKEN_REUSED = true ]
then
  echo "$SCRIPT_NAME You have been using an auth token that was not created by these scripts, you will need to destroy the auth token by hand"
  echo "and then remove AUTH_TOKEN_REUSED, AUTH_TOKEN_OCID and if present AUTH_TOKEN from $SETTINGS" 
  exit 0
fi

if [ -z $AUTH_TOKEN_OCID ]
then 
  echo "$SCRIPT_NAME No auth token OCID information found, cannot destroy something that cant be identifed"
  exit 3
fi

if [ -z $USER_OCID ]
then
  echo "$SCRIPT_NAME No user OCID information found, this is required to destroy the auth token,  you will need to destroy the auth token by hand"
  echo "clearing values in $SETTINGS"
  bash ./delete-from-saved-settings.sh AUTH_TOKEN_OCID
  bash ./delete-from-saved-settings.sh AUTH_TOKEN_REUSED
  bash ./delete-from-saved-settings.sh AUTH_TOKEN
  exit 4
fi


echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`

OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

echo "Destroying auth token with id $AUTH_TOKEN_OCID "
oci iam auth-token delete --force --user-id $USER_OCID --auth-token-id $AUTH_TOKEN_OCID --region $OCI_HOME_REGION

bash ./delete-from-saved-settings.sh AUTH_TOKEN_OCID
bash ./delete-from-saved-settings.sh AUTH_TOKEN_REUSED
bash ./delete-from-saved-settings.sh AUTH_TOKEN