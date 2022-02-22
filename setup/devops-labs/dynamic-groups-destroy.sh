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
cd ../common/dynamic-groups

bash ./dynamic-group-destroy.sh "$USER_INITIALS"BuildDynamicGroup
bash ./dynamic-group-destroy.sh "$USER_INITIALS"CodeReposDynamicGroup 
bash ./dynamic-group-destroy.sh "$USER_INITIALS"DeployDynamicGroup