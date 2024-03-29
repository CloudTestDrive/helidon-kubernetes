#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -ne 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "1st is the name of the setting e.g. OCIR_HOST - the script will appaned / prepend the required strings around that value"
  echo "The script will try and locate a pre-set OCID for the secret from the settings file, and will then try and get it's contents"
  exit 1
fi
SETTINGS_NAME=$1

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

SECRET_NAME=`bash ./get-vault-secret-name.sh $SETTINGS_NAME`
VAULT_SECRET_NAME=`bash ./get-vault-secret-name.sh $SECRET_NAME`
VAULT_SECRET_OCID_NAME=`bash ./get-vault-secret-ocid-name.sh $SECRET_NAME`
if [ -z "${!VAULT_SECRET_OCID_NAME}" ] 
then
  echo "Can't locate the variable $VAULT_SECRET_OCID_NAME (or it has no value) which holds the OCID for"
  echo "$VAULT_SECRET_NAME which contains the contents for setting $SETTINGS_NAME"
  exit 1
fi
VAULT_SECRET_OCID="${!VAULT_SECRET_OCID_NAME}"

VAULT_SECRET_CONTENTS=`oci secrets secret-bundle get --secret-id $VAULT_SECRET_OCID --stage CURRENT | jq -r '.data."secret-bundle-content".content' | base64 --decode`

if [ -z "$VAULT_SECRET_CONTENTS" ]
then
  echo "Unable to retrivve contents for vault secrets $VAULT_SECRET_NAME which holds the vault for setting $SETTINGS_NAME, does the OCID $VAULT_SECRET_OCID actually exist ?"
  exit 2
fi

echo "For $SETTINGS_NAME use OCID $VAULT_SECRET_OCID which points to vault secret $VAULT_SECRET_NAME and has contents $VAULT_SECRET_CONTENTS"