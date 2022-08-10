#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi
if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi

cd ../common
VAULT_KEY_NAME="$USER_INITIALS"AES
VAULT_KEY_REUSED_NAME=`bash vault/vault-key-get-var-name-reused.sh $VAULT_KEY_NAME`
cd ..

echo "Waiting for devops services and configuration to be available." 

export WAIT_LOOP_COUNT=60

bash ./wait-for-service-availability.sh VAULT_REUSED $VAULT_KEY_REUSED_NAME DEVOPS_SSH_API_KEY_CONFIGURED DEVOPS_DYNAMIC_GROUPS_CONFIGURED DEVOPS_POLICIES_CONFIGURED


RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of more of the services associated with VAULT_REUSED VAULT_KEY_REUSED_NAME SSH_API_KEY_CONFIGURED DYNAMIC_GROUPS_CONFIGURED POLICIES_CONFIGURED did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0