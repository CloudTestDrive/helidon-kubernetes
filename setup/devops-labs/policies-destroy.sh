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

if [ -z "$DEVOPS_POLICIES_CONFIGURED" ]
then
  echo "DevOps policies not configured"
  exit 0
else
  echo "Removing configured DevOps policies"
fi
SAVED_DIR=`pwd`

cd ../common/policies

bash ./policy-destroy.sh "$USER_INITIALS"DevOpsCodeRepoPolicy
bash ./policy-destroy.sh "$USER_INITIALS"DevOpsBuildPolicy 
bash ./policy-destroy.sh "$USER_INITIALS"DevOpsDeployPolicy


# delete script is in common, we are in common/policies
bash ../delete-from-saved-settings.sh DEVOPS_POLICIES_CONFIGURED
cd $SAVED_DIR