#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires two arguments"
  echo "the name of the log to destroy"
  echo "the name of the containing log group"
  exit 1
fi

LOG_NAME=$1
LOG_GROUP_NAME=$2
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

# get the possible reuse and OCID for the log group itself
echo "Getting var names for log $LOG_NAME in log group $LOG_GROUP_NAME"
LOG_OCID_NAME=`bash ./get-log-ocid-name.sh $LOG_NAME $LOG_GROUP_NAME`
LOG_REUSED_NAME=`bash ./get-log-reused-name.sh $LOG_NAME $LOG_GROUP_NAME`

if [ -z "${!LOG_REUSED_NAME}" ]
then
  echo "No reuse information for log $LOG_NAME in log group $LOG_GROUP_NAME, perhaps it's already been removed ? Cannot safely proceed with deleting repo"
  exit 0
fi

if [ "${!LOG_REUSED_NAME}" = true ]
then
  echo "Cannot delete a log not created by these scripts, please delete the log by hand"
  bash ../delete-from-saved-settings.sh $LOG_OCID_NAME
  bash ../delete-from-saved-settings.sh $LOG_REUSED_NAME
  exit 0
fi
# Get the OCID for the repo
DEVOPS_REPO_OCID="${!DEVOPS_REPO_OCID_NAME}"
if [ -z "$DEVOPS_REPO_OCID" ]
then
  echo "No log OCID information, cannot proceed"
  exit 0
fi


echo "Deleting log $LOG_NAME in log group $LOG_GROUP_NAME"

oci logging log delete --log-id  $DEVOPS_REPO_OCID --force --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $LOG_OCID_NAME
bash ../delete-from-saved-settings.sh $LOG_REUSED_NAME

