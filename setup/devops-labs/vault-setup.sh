#!/bin/bash -f
# now actually create the host ane nameslace secrets

SAVED_DIR=`pwd`

cd ../common/vault

bash ./vault-core-setup.sh

RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-core-setup.sh returned an error, unable to continue"
  exit $RESP
fi