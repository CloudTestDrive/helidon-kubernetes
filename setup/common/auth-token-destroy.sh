#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

if [ -z $AUTH_TOKEN_REUSED ]
then
  echo No reuse information for compartment cannot safely contiue, you will have to destroy it manually
  exit 1
fi

if [ $AUTH_TOKEN_REUSED = true ]
then
  echo You have been using an auth token that was not created by these scripts, you will need to destroy the auth token by hand
  echo and then remove AUTH_TOKEN_REUSED, AUTH_TOKEN_OCID and if present AUTH_TOKEN from $SETTINGS 
  exit 2
fi

if [ -z $AUTH_TOKEN_OCID ]
then 
  echo No auth token OCID information found, cannot destroy something that cant be identifed
  exit 3
fi

if [ -z $USER_OCID ]
then
  echo No user OCID information found, this is required to destroy the auth token,  you will need to destroy the auth token by hand
  echo and then remove AUTH_TOKEN_REUSED, AUTH_TOKEN_OCID and if present AUTH_TOKEN from $SETTINGS 
  exit 4
fi

echo Destroying auth token with id $AUTH_TOKEN_OCID 
oci iam auth-token delete --force --user-id $USER_OCID --auth-token-id $AUTH_TOKEN_OCID

bash ./delete-from-saved-settings.sh AUTH_TOKEN_OCID
bash ./delete-from-saved-settings.sh AUTH_TOKEN_REUSED
bash ./delete-from-saved-settings.sh AUTH_TOKEN