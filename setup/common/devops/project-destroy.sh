#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument"
  echo "the name of the devops project to destroy"
  exit 1
fi

DEVOPS_PROJECT_NAME=$1
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

# get the possible reuse and OCID for the devops project itself
echo "Getting var names for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID_NAME=`bash ./get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_REUSED_NAME=`bash ./get-project-reused-name.sh $DEVOPS_PROJECT_NAME`

if [ -z "${!DEVOPS_PROJECT_REUSED_NAME}" ]
then
  echo "No reuse information for devops project $DEVOPS_PROJECT_NAME , perhaps it's already been removed ? Cannot safely proceed with deleting project"
  exit 0
fi

if [ "${!DEVOPS_PROJECT_REUSED_NAME}" = true ]
then
  echo "Cannot delete a devops project not created by these scripts, please delete the project by hand"
  exit 0
fi

if [ -z "${!DEVOPS_PROJECT_OCID_NAME}" ]
then
  echo "No devops project OCID information, cannot proceed"
  exit 0
fi

DEVOPS_PROJECT_OCID="${!DEVOPS_PROJECT_OCID_NAME}"

echo "Deleting devops project $DEVOPS_PROJECT_NAME"

oci devops project delete --project-id  $DEVOPS_PROJECT_OCID --force  --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $DEVOPS_PROJECT_OCID_NAME
bash ../delete-from-saved-settings.sh $DEVOPS_PROJECT_REUSED_NAME

