#!/bin/bash -f

bash ./vault-key-destroy.sh RSA
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-key-destroy on key RSA returned an error, unable to continue"
  exit $RESP
fi
bash ./vault-key-destroy.sh AES
RESP=$?
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