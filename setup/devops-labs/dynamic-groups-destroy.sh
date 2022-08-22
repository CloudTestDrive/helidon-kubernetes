#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot contiue"
    exit 10
fi

source $SETTINGS

if [ -z "$DEVOPS_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "Dynamic groups for devops not configured"
  exit 0
else
  echo "Removing configured dynamic groups for devops"
fi
SAVED_DIR=`pwd`


cd ../common/dynamic-groups

bash ./dynamic-group-destroy.sh "$USER_INITIALS"BuildDynamicGroup
bash ./dynamic-group-destroy.sh "$USER_INITIALS"CodeReposDynamicGroup 
bash ./dynamic-group-destroy.sh "$USER_INITIALS"DeployDynamicGroup

# delete script is in common, we are in common/dynamic-groups
bash ../delete-from-saved-settings.sh DEVOPS_DYNAMIC_GROUPS_CONFIGURED
cd $SAVED_DIR