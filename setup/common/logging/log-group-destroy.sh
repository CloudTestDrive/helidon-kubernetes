#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument"
  echo "the name of the log group to destroy"
  exit 1
fi

LOG_GROUP_NAME=$1
echo "Getting var names for log group $LOG_GROUP_NAME"
LOG_GROUP_OCID_NAME=`bash ./get-log-group-ocid-name.sh $LOG_GROUP_NAME`
LOG_GROUP_REUSED_NAME=`bash ./get-log-group-reused-name.sh $LOG_GROUP_NAME`
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



if [ -z "${!LOG_GROUP_REUSED_NAME}" ]
then
  echo "No reuse information, , perhaps it's already been removed ? Cannot safely proceed with deleting log group"
  exit 0
fi

if [ "${!LOG_GROUP_REUSED_NAME}" = true ]
then
  echo "Cannot delete a log group group not created by these scripts, deleting the saved settings, please delete the log group by hand"
  bash ../delete-from-saved-settings.sh $LOG_GROUP_OCID_NAME
  bash ../delete-from-saved-settings.sh $LOG_GROUP_REUSED_NAME
  exit 0
  
fi

if [ -z "${!LOG_GROUP_OCID_NAME}" ]
then
  echo "No log group OCID information, cannot proceed"
  exit 0
fi

LOG_GROUP_OCID="${!LOG_GROUP_OCID_NAME}"

echo "Deleting log group $LOG_GROUP_NAME"

oci logging log-group delete --log-group-id  $LOG_GROUP_OCID --force  --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $LOG_GROUP_OCID_NAME
bash ../delete-from-saved-settings.sh $LOG_GROUP_REUSED_NAME

