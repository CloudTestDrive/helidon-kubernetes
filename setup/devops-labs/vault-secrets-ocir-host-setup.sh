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

if [ -z $VAULT_SECRET_OCIR_HOST_REUSED ] 
then
  echo No existing reuse information for OCIR_HOST_VAULT, continuing
else
  echo The OCIR_HOST_VAULT secret has already been setup, will not be recreated. this script will exit
  exit 0
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 11
fi

if [ -z $VAULT_OCID ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo Found vault
fi

if [ -z $VAULT_KEY_OCID ]
then
  echo "No vault key OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 13
else
  echo Found vault key
fi

if [ -z $OCIR_STOREFRONT_LOCATION ]
then
  echo "No OCIR host for the storefront image set, have you run the image-environment-setup.sh or ocir-setup.sh script ?"
  echo "Cannot continue"
  exit 14
else
  echo Found vault key
fi

VAULT_SECRET_NAME=OCIR_HOST_VAULT
#lets see it it exists already
echo "Checking if secret $VAULT_SECRET_NAME already exists"
VAULT_SECRET_OCIR_HOST_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state ACTIVE --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`
if [ -z $VAULT_SECRET_OCIR_HOST_OCID ]
then
  echo "secret $VAULT_SECRET_NAME Does not exist, creating it and setting it to $OCIR_STOREFRONT_LOCATION"
  BASE64_OCIR_HOST_VAULT=`echo $OCIR_STOREFRONT_LOCATION | base64`

  # Create the secrets
  VAULT_SECRET_OCIR_HOST_OCID=`oci vault secret create-base64 --compartment-id $COMPARTMENT_OCID --secret-name $VAULT_SECRET_NAME --vault-id $VAULT_OCID --description 'OCIR hostname' --key-id $VAULT_KEY_OCID  --secret-content-content $BASE64_OCIR_HOST_VAULT | jq -j '.data.id'` 
  echo "VAULT_SECRET_OCIR_HOST_OCID=$VAULT_SECRET_OCIR_HOST_OCID" >> $SETTINGS
  echo "VAULT_SECRET_OCIR_HOST_REUSED=false" >> $SETTINGS
else
  # it exists, we will just re-use it
  echo "$VAULT_SECRET_NAME already exists, reusing it, if you need to change the contents you will have to do that manually"
  echo "VAULT_SECRET_OCIR_HOST_OCID=$VAULT_SECRET_OCIR_HOST_OCID" >> $SETTINGS
  echo "VAULT_SECRET_OCIR_HOST_REUSED=true" >> $SETTINGS

fi
