#!/bin/bash -f
# now actually create the host ane nameslace secrets

SAVED_DIR=`pwd`

cd ../common/vault

bash ./vault-key-destroy.sh AES

if [ $RESP -ne 0 ]
then
  echo "Vault-key-destroy on key AES returned an error, unable to continue"
  exit $RESP
fi
bash ./vault-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-destroy returned an error, unable to continue"
  exit $RESP
fi