#!/bin/bash -f

cd ../common

echo "Waiting for devops services and configuration to be available." 

export WAIT_LOOP_COUNT=60

bash ./wait-for-service-availability.sh VAULT_REUSED VAULT_KEY_REUSED SSH_API_KEY_CONFIGURED DYNAMIC_GROUPS_CONFIGURED POLICIES_CONFIGURED


RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of more of the services associated with VAULT_REUSED VAULT_KEY_REUSED SSH_API_KEY_CONFIGURED DYNAMIC_GROUPS_CONFIGURED POLICIES_CONFIGURED did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0