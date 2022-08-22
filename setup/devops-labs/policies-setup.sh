#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z "$DEVOPS_POLICIES_CONFIGURED" ]
then
  echo "DevOps policies not configured, setting up"
else
  echo "DevOps policies already configured"
  exit 0
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "$SCRIPT_NAME Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "$SCRIPT_NAME Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi

SAVED_DIR=`pwd`
cd ../common/policies


FINAL_RESP="0"
bash ./policy-setup.sh "$USER_INITIALS"DevOpsCodeRepoPolicy dynamic-group "$USER_INITIALS"CodeReposDynamicGroup "This policy allows the dynamic group of code repo resources resources to create trigger the build process"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy "$USER_INITIALS"DevOpsCodeRepoPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
bash ./policy-setup.sh "$USER_INITIALS"DevOpsBuildPolicy dynamic-group "$USER_INITIALS"BuildDynamicGroup "This policy allows the dynamic group of build resources resources to create build runners, and trigger deployments"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy "$USER_INITIALS"DevOpsBuildPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
bash ./policy-setup.sh "$USER_INITIALS"DevOpsDeployPolicy dynamic-group "$USER_INITIALS"DeployDynamicGroup "This policy allows the deployment tooling to interact with the destination systems (OKE, Functions etc.)"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy "$USER_INITIALS"DevOpsDeployPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/policies
  bash ../delete-from-saved-settings.sh DEVOPS_POLICIES_CONFIGURED
  echo DEVOPS_POLICIES_CONFIGURED=true >> $SETTINGS
  exit $FINAL_RESP
fi

cd $SAVED_DIR