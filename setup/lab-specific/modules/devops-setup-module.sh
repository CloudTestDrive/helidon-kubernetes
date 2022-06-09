#!/bin/bash -f

if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi

LOGS_DIR=$HOME/setup-logs
if [ "$PARALLEL_SETUP" = "true" ]
then
  mkdir -p $LOGS_DIR
fi

SETUP_DIR=$HOME/helidon-kubernetes/setup
MODULES_DIR=$SETUP_DIR/lab-specific/modules

SAVED_PWD=`pwd`

cd $COMMON_DIR

if [ "$PARALLEL_SETUP" = "true" ]
then
  VAULT_LOG=$LOGS_DIR/vaultSetupLogs.txt
  echo "Creating the vault and key in the background, please ensure they have been created before running any service against it"
  echo "You can see the progress of the vault creation in the log file at $VAULT_LOG"
  bash ./vault-setup.sh 2>&1 > $VAULT_LOG &
else
  bash ./vault-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Vault returned an error, unable to continue"
    exit $RESP
  fi
fi

cd $SAVED_PWD

cd $DEVOPS_LABS_DIR

if [ "$PARALLEL_SETUP" = "true" ]
then
  DEVOPS_SECURITY_LOG=$LOGS_DIR/devopsSecuritySetupLogs.txt
  echo "Configuring the required policies for devops in the background, please ensure they have been created before running any service against it"
  echo "You can see the progress of the devops security configuration in the log file at $DEVOPS_SECURITY_LOG"
  bash ./security-setup.sh 2>&1 > $DEVOPS_SECURITY_LOG &
else
  bash ./security-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Security configuration for devops returned an error, unable to continue"
    exit $RESP
  fi
fi

if [ "$PARALLEL_SETUP" = "true" ]
then
  cd $DEVOPS_LABS_DIR
  bash ./wait-for-devops-services.sh
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Problem setting up devops securty setup, cannot continue"
    exit $RESP
  fi
fi

exit 0