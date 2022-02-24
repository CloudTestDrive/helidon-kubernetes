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
cd ../common/policies

bash ./policy-destroy.sh "$USER_INITIALS"DevOpsCodeRepoPolicy
bash ./policy-destroy.sh "$USER_INITIALS"DevOpsBuildPolicy 
bash ./policy-destroy.sh "$USER_INITIALS"DevOpsDeployPolicy