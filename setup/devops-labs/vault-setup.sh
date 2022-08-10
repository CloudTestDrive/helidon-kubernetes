#!/bin/bash -f
# now actually create the host ane nameslace secrets

SAVED_DIR=`pwd`

cd ../common/vault

bash ./vault-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-setup returned an error, unable to continue"
  exit $RESP
fi
bash ./vault-key-setup.sh AES AES 32

if [ $RESP -ne 0 ]
then
  echo "Vault-key-setup on key AES returned an error, unable to continue"
  exit $RESP
fi