#!/bin/bash -f

REQUIRED_ARGS_COUNT=3
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy stage to destroy"
  echo "the name of the containing deploy pipeline (which must have"
  echo "  already been created with the deploy-pipeline-setup.sh script)"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  exit 1
fi

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


DEPLOY_STAGE_NAME=$1
DEVOPS_DEPLOY_PIPELINE_NAME=$2
DEVOPS_PROJECT_NAME=$3

echo "Getting var names for devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME"
DEVOPS_DEPLOY_PIPELINE_OCID_NAME=`bash ./get-deploy-pipeline-ocid-name.sh $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_PIPELINE_OCID="${!DEVOPS_DEPLOY_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_PIPELINE_OCID" ]
then
  echo "No OCID found for devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi

echo "Getting var names for stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
DEPLOY_STAGE_OCID_NAME=`bash ./get-deploy-stage-ocid-name.sh $DEPLOY_STAGE_NAME $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEPLOY_STAGE_REUSED_NAME=`bash ./get-deploy-stage-reused-name.sh $DEPLOY_STAGE_NAME $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

DEPLOY_STAGE_OCID="${!DEPLOY_STAGE_OCID_NAME}"
if [ -z "$DEPLOY_STAGE_OCID" ]
then
  echo "devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be located, has it been created by these scripts ?"
  exit 0
fi

echo "Checking for stages dependent on deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME "
DEPENDENT_STAGES_COUNT=`oci devops deploy-stage list --pipeline-id "$DEVOPS_DEPLOY_PIPELINE_OCID" --all | jq "[ .data.items[] | .\"pipeline-stage-predecessor-collection\".items[] | select (.id==\"$DEPLOY_STAGE_OCID\") ] | length "`

if [ "$DEPENDENT_STAGES_COUNT" -gt 0 ]
then
  echo "devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME has $DEPENDENT_STAGES_COUNT dependent stages, cannot delete it"
  exit 3
fi

echo "No dependencies, deleting"
oci devops deploy-stage delete --stage-id "$DEPLOY_STAGE_OCID" --force --wait-for-state SUCCEEDED --wait-interval-seconds 5

bash ../delete-from-saved-settings.sh $DEPLOY_STAGE_OCID_NAME
bash ../delete-from-saved-settings.sh $DEPLOY_STAGE_REUSED_NAME