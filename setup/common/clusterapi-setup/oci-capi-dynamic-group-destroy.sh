#!/bin/bash -f
SCRIPT_NAME=`basename $0`

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


if [ -z "$CLUSTER_API_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "Cluster API Dynamic groups not configured, can't remove"
  exit 0
else
  echo "Cluster API Dynamic groups configured by this script, removing"
fi


if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi

SAVED_DIR=`pwd`

cd ../dynamic-groups

FINAL_RESP="0"
bash ./dynamic-group-destroy.sh "$USER_INITIALS"ClusterAPIDynamicGroup
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying up dynamic group "$USER_INITIALS"ClusterAPIDynamicGroup response is $RESP"
  FINAL_RESP=$RESP
fi
cd $SAVED_DIR

if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/dynamic-groups
  bash ../delete-from-saved-settings.sh CLUSTER_API_DYNAMIC_GROUPS_CONFIGURED
  exit $FINAL_RESP
fi