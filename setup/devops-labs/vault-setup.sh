#!/bin/bash -f
# now actually create the host ane nameslace secrets
SCRIPT_NAME=`basename $0`

SAVED_DIR=`pwd`

cd ../common/vault

bash ./vault-core-setup.sh

RESP=$?
if [ $RESP -ne 0 ]
then
  echo "$SCRIPT_NAME Vault-core-setup.sh returned an error, unable to continue"
  exit $RESP
fi