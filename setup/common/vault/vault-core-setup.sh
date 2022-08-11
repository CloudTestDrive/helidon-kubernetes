#!/bin/bash -f

bash ./vault-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-setup returned an error, unable to continue"
  exit $RESP
fi
bash ./vault-key-setup.sh AES AES 32
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-key-setup on key AES returned an error, unable to continue"
  exit $RESP
fi
bash ./vault-key-setup.sh RSA RSA 512
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Vault-key-setup on key RSA returned an error, unable to continue"
  exit $RESP
fi