#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires two arguments"
  echo "the name of the devops build pipeline to destroy"
  echo "the name of the containing devops project"
  exit 1
fi

DEVOPS_BUILD_PIPELINE_NAME=$1
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

# get the possible reuse and OCID for the devops build pipeline itself
echo "Getting var names for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
DEVOPS_BUILD_PIPELINE_OCID_NAME=`bash ./get-build-pipeline-ocid-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_REUSED_NAME=`bash ./get-build-pipeline-reused-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEVOPS_BUILD_PIPELINE_REUSED_NAME}" ]
then
  echo "No reuse information for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME, perhaps it's already been removed ? Cannot safely proceed with deleting build pipeline"
  exit 0
fi

if [ "${!DEVOPS_BUILD_PIPELINE_REUSED_NAME}" = true ]
then
  echo "Cannot delete a devops build pipeline not created by these scripts, please delete the build pipeline by hand"
  bash ../delete-from-saved-settings.sh $DEVOPS_BUILD_PIPELINE_OCID_NAME
  bash ../delete-from-saved-settings.sh $DEVOPS_BUILD_PIPELINE_REUSED_NAME
  exit 0
fi
# Get the OCID for the build pipeline
DEVOPS_BUILD_PIPELINE_OCID="${!DEVOPS_BUILD_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "No devops build pipeline OCID information, cannot proceed"
  exit 0
fi


echo "Deleting devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME  in project $DEVOPS_PROJECT_NAME"

oci devops build-pipeline delete --build-pipeline-id  $DEVOPS_BUILD_PIPELINE_OCID --force --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $DEVOPS_BUILD_PIPELINE_OCID_NAME
bash ../delete-from-saved-settings.sh $DEVOPS_BUILD_PIPELINE_REUSED_NAME

