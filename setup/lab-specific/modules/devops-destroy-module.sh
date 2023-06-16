#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings, cannot continue"
  exit 10
fi

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
cd $DEVOPS_LABS_DIR
bash ./vault-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Vault destroy returned an error, unable to continue"
  exit $RESP
fi

exit 0
cd $SAVED_PWD



exit 0