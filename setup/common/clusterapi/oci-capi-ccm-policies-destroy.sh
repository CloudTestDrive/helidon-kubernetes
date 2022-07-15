#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z "$CLUSTER_API_CCM_POLICIES_CONFIGURED" ]
then
  echo "Cluster API ccm policies not configured, unable to proceed"
  exit 0
else
  echo "Cluster API ccm policies configured, will remove them"
fi
if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi
SAVED_DIR=`pwd`

cd ../policies
FINAL_RESP="0"
bash ./policy-destroy.sh "$USER_INITIALS"ClusterAPICCMRepoPolicy
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying policy "$USER_INITIALS"ClusterAPICCMRepoPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
cd $SAVED_DIR
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/policies
  bash ../delete-from-saved-settings.sh CLUSTER_API_CCM_POLICIES_CONFIGURED
  exit $FINAL_RESP
fi