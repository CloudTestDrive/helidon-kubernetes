#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires two arguments"
  echo "the name of the devops trigger to destroy"
  echo "the name of the containing devops project"
  exit 1
fi

DEVOPS_TRIGGER_NAME=$1
DEVOPS_PROJECT_NAME=$2
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

# get the possible reuse and OCID for the devops trigger itself
echo "Getting var names for devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
DEVOPS_TRIGGER_OCID_NAME=`bash ./get-trigger-ocid-name.sh $DEVOPS_TRIGGER_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_TRIGGER_REUSED_NAME=`bash ./get-trigger-reused-name.sh $DEVOPS_TRIGGER_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEVOPS_TRIGGER_REUSED_NAME}" ]
then
  echo "No reuse information for devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME, perhaps it's already been removed ? Cannot safely proceed with deleting trigger"
  exit 0
fi

if [ "${!DEVOPS_TRIGGER_REUSED_NAME}" = true ]
then
  echo "Cannot delete a devops trigger not created by these scripts, please delete the trigger by hand"
  bash ../delete-from-saved-settings.sh $DEVOPS_TRIGGER_OCID_NAME
  bash ../delete-from-saved-settings.sh $DEVOPS_TRIGGER_REUSED_NAME
  exit 0
fi
# Get the OCID for the trigger
DEVOPS_TRIGGER_OCID="${!DEVOPS_TRIGGER_OCID_NAME}"
if [ -z "$DEVOPS_TRIGGER_OCID" ]
then
  echo "No devops trigger OCID information, cannot proceed"
  exit 0
fi


echo "Deleting devops trigger $DEVOPS_TRIGGER_NAME  in project $DEVOPS_PROJECT_NAME"

oci devops trigger delete --trigger-id  $DEVOPS_TRIGGER_OCID --force --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $DEVOPS_TRIGGER_OCID_NAME
bash ../delete-from-saved-settings.sh $DEVOPS_TRIGGER_REUSED_NAME

