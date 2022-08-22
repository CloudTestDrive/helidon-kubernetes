#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
SAVED_DIR=`pwd`


cd ../common/vault
FINAL_RESP=0
bash ./vault-individual-secret-destroy.sh OCIR_HOST
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "$SCRIPT_NAME Failure deleting the vault secret OCIR_HOST, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  FINAL_RESP=$RESP
fi 

bash ./vault-individual-secret-destroy.sh OCIR_STORAGE_NAMESPACE
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "$SCRIPT_NAME Failure deleting the vault secret OCIR_STORAGE_NAMESPACE, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  FINAL_RESP=$RESP
fi 

cd $SAVED_DIR
exit $FINAL_RESP