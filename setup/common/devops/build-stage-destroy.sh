#!/bin/bash -f

REQUIRED_ARGS_COUNT=3
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops build stage to destroy"
  echo "the name of the containing build pipeline (which must have"
  echo "  already been created with the build-pipeline-setup.sh script)"
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


BUILD_STAGE_NAME=$1
DEVOPS_BUILD_PIPELINE_NAME=$2
DEVOPS_PROJECT_NAME=$3

echo "Getting var names for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME"
DEVOPS_BUILD_PIPELINE_OCID_NAME=`bash ./get-build-pipeline-ocid-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_OCID="${!DEVOPS_BUILD_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "No OCID found for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi

echo "Getting var names for stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
BUILD_STAGE_OCID_NAME=`bash ./get-build-stage-ocid-name.sh $BUILD_STAGE_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
BUILD_STAGE_REUSED_NAME=`bash ./get-build-stage-reused-name.sh $BUILD_STAGE_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

BUILD_STAGE_OCID="${!BUILD_STAGE_OCID_NAME}"
if [ -z "$BUILD_STAGE_OCID" ]
then
  echo "devops build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be located, has it been created by these scripts ?"
  exit 0
fi

echo "Checking for stages dependent on build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME "
DEPENDENT_STAGES_COUNT=`oci devops build-pipeline-stage list --build-pipeline-id "$DEVOPS_BUILD_PIPELINE_OCID" --all | jq "[ .data.items[] | .\"build-pipeline-stage-predecessor-collection\".items[] | select (.id==\"$BUILD_STAGE_OCID\") ] | length "`

if ( $DEPENDENT_STAGES_COUNT -ne 0 )
then
  echo "devops build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME has dependent stages, cannot delete it"
  exit 3
fi

echo "No dependencies, deleting"
oci devops build-pipeline-stage delete --stage-id "$BUILD_STAGE_OCID" --force --wait-for-state SUCCEEDED 

bash ../delete-from-saved-settings.sh $BUILD_STAGE_OCID_NAME
bash ../delete-from-saved-settings.sh $BUILD_STAGE_REUSED_NAME