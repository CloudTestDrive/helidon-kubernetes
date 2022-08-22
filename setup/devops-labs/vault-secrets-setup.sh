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

if [ -z $COMPARTMENT_OCID ]
then
  echo "$SCRIPT_NAME Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 11
fi

if [ -z $VAULT_OCID ]
then
  echo "$SCRIPT_NAME No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo Found vault
fi
SAVED_DIR=`pwd`
# check for the keys
cd ../common/vault
VAULT_KEY_NAME_BASE=AES
VAULT_KEY_NAME=`bash ./vault-key-get-key-name.sh $VAULT_KEY_NAME_BASE`
VAULT_KEY_OCID_NAME=`bash ./vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`
VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"

if [ -z $VAULT_KEY_OCID ]
then
  echo "$SCRIPT_NAME No vault key OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 13
else
  echo Found vault key
fi

# now actually create the host ane nameslace secrets


FINAL_RESP=0
if [ -z $OCIR_STOREFRONT_LOCATION ]
then
  echo "No OCIR host variable for the storefront image set, have you run the image-environment-setup.sh or ocir-setup.sh script ?"
  echo "Cannot continue setting up this secret"
else
  bash ./vault-individual-secret-setup.sh $VAULT_KEY_NAME_BASE OCIR_HOST 'OCIR hostname' $OCIR_STOREFRONT_LOCATION
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure creating the vault secret OCIR_HOST, exit code is $RESP, cannot continue"
    echo "Please review the output and rerun the script"
    FINAL_RESP=$RESP
  fi 
fi

# the object storage namespace should exist as it's a tenancy level property, so no need to check
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

bash ./vault-individual-secret-setup.sh $VAULT_KEY_NAME_BASE OCIR_STORAGE_NAMESPACE 'OCIR Storage namespace' $OBJECT_STORAGE_NAMESPACE
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the vault secret OCIR_HOST, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  FINAL_RESP=$RESP
fi 

cd $SAVED_DIR

exit $FINAL_RESP