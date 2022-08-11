#!/bin/bash -f
# now actually create the host ane nameslace secrets

cd ../common/vault

bash ./vault-core-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-core-destroy returned an error, unable to continue"
  exit $RESP
fi