#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export CA_SETTINGS=cert-authority-settings.sh

if [ -f $CA_SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing CA settings information"
    source $CA_SETTINGS
  else 
    echo "$SCRIPT_NAME No existing CA settings cannot continue"
    exit 11
fi

cd ../vault
# the script will prefix the initials stuff for us
bash ./vault-key-setup.sh $CERT_VAULT_KEY_NAME $CERT_VAULT_KEY_TYPE $CERT_VAULT_KEY_SIZE
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "$SCRIPT_NAME Vault-key-setup on key $CERT_VAULT_KEY_NAME returned an error, unable to continue"
  exit $RESP
fi