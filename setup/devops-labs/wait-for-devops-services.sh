#!/bin/bash -f

cd ../common

echo "Waiting for devops services and configuration to be available." 

bash ./wait-for-service-availability.sh VAULT_REUSED VAULT_KEY SSH_API_KEY_CONFIGURED DYNAMIC_GROUPS_CONFIGURED POLICIES_CONFIGURED