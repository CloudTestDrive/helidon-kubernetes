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
    #echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

VAULT_SECRET_NAME=`bash ./get-vault-secret-name.sh $SETTINGS_NAME`
VAULT_SECRET_OCID=`bash ./vault-individual-secret-oicd-retrieve.sh $SETTINGS_NAME`
echo $VAULT_SECRET_OCID