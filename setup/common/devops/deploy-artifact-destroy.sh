#!/bin/bash -f

REQUIRED_ARGS_COUNT=2
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy artifact to destroy"
  echo "the name of the containing devops project"
  exit 1
fi

DEVOPS_DEPLOY_ARTIFACT_NAME=$1
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

# get the possible reuse and OCID for the devops build pipeline itself
echo "Getting var names for devops build pipeline $DEVOPS_DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME"
DEVOPS_DEPLOY_ARTIFACT_OCID_NAME=`bash ./get-deploy-artifact-ocid-name.sh $DEVOPS_DEPLOY_ARTIFACT_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_ARTIFACT_REUSED_NAME=`bash ./get-deploy-artifact-reused-name.sh $DEVOPS_DEPLOY_ARTIFACT_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEVOPS_DEPLOY_ARTIFACT_REUSED_NAME}" ]
then
  echo "No reuse information for devops deploy artifact $DEVOPS_DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME, perhaps it's already been removed ? Cannot safely proceed with deleting build pipeline"
  exit 0
fi

if [ "${!DEVOPS_DEPLOY_ARTIFACT_REUSED_NAME}" = true ]
then
  echo "Cannot delete a devops deploy artifact not created by these scripts, please delete the build pipeline by hand"
  bash ../delete-from-saved-settings.sh $DEVOPS_DEPLOY_ARTIFACT_OCID_NAME
  bash ../delete-from-saved-settings.sh $DEVOPS_DEPLOY_ARTIFACT_REUSED_NAME
  exit 0
fi
# Get the OCID for the build pipeline
DEVOPS_DEPLOY_ARTIFACT_OCID="${!DEVOPS_DEPLOY_ARTIFACT_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_ARTIFACT_OCID" ]
then
  echo "No devops deploy artifact OCID information, cannot proceed"
  exit 0
fi


echo "Deleting devops deploy artifact $DEVOPS_DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME"

oci devops deploy-artifact delete  --artifact-id  $DEVOPS_DEPLOY_ARTIFACT_OCID --force --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $DEVOPS_DEPLOY_ARTIFACT_OCID_NAME
bash ../delete-from-saved-settings.sh $DEVOPS_DEPLOY_ARTIFACT_REUSED_NAME

