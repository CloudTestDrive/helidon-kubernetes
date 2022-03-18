#!/bin/bash -f
SETUP_DIR=$HOME/helidon-kubernetes/setup
MODULES_DIR=$SETUP_DIR/lab-specific/modules

SAVED_PWD=`pwd`

cd $COMMON_DIR
bash ./vault-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Vault returned an error, unable to continue"
  exit $RESP
fi

exit 0
cd $SAVED_PWD

cd $DEVOPS_LABS_DIR
bash ./security-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Security setup for devops returned an error, unable to continue"
  exit $RESP
fi

exit 0