#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the vault setting to process"
  exit -1
fi
SETTINGS_NAME=$1
VAULT_SECRET_NAME=`bash ./get-vault-secret-var-name.sh $SETTINGS_NAME`
VAULT_SECRET_NAME_CAPS=`bash ../settings/to-valid-name.sh $VAULT_SECRET_NAME`
VAULT_SECRET_OCID_NAME="$VAULT_SECRET_NAME_CAPS"_OCID
echo $VAULT_SECRET_OCID_NAME