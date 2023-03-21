#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the vault secret to process"
  exit -1
fi
SETTINGS_NAME=$1

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
VAULT_SERET_OCID_NAME=`bash ./get-vault-secret-ocid-name.sh`

VAULT_SERET_OCID="${!VAULT_SERET_OCID_NAME}"
if [ -z "$VAULT_SERET_OCID" ]
then
  echo "Cannot locate OCID for vault secret $SETTINGS_NAME"
  exit 1
fi
echo $VAULT_SERET_OCID