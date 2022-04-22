#!/bin/bash -f
SETUP_DIR=$HOME/helidon-kubernetes/setup
MODULES_DIR=$SETUP_DIR/lab-specific/modules

SAVED_PWD=`pwd`

cd $DEVOPS_LABS_DIR
bash ./vault-secrets-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Vault secrets destroy returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD
cd $DEVOPS_LABS_DIR
bash ./security-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Security destroy for devops returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD

cd $COMMON_DIR
bash ./vault-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Vault destroy eturned an error, unable to continue"
  exit $RESP
fi

exit 0
cd $SAVED_PWD



exit 0