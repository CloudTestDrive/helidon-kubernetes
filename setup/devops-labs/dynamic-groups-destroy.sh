#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

source $SETTINGS

if [ -z "$DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "Dynamic groups not configured"
  exit 0
else
  echo "Removing configured dynamic groups"
fi
SAVED_DIR=`pwd`


cd ../common/dynamic-groups

bash ./dynamic-group-destroy.sh "$USER_INITIALS"BuildDynamicGroup
bash ./dynamic-group-destroy.sh "$USER_INITIALS"CodeReposDynamicGroup 
bash ./dynamic-group-destroy.sh "$USER_INITIALS"DeployDynamicGroup

# delete script is in common, we are in common/dynamic-groups
bash ../delete-from-saved-settings.sh DEVOPS_DYNAMIC_GROUPS_CONFIGURED
cd $SAVED_DIR