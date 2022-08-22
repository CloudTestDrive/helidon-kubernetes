#!/bin/bash -f
# now actually create the host ane nameslace secrets
SCRIPT_NAME=`basename $0`

cd ../common/vault

bash ./vault-core-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "$SCRIPT_NAME Vault-core-destroy returned an error, unable to continue"
  exit $RESP
fi