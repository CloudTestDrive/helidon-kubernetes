#!/bin/bash -f

REQUIRED_ARGS_COUNT=5
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy stage to create"
  echo "the name of the containing build pipeline (which must have"
  echo "  already been created with the build-pipeline-setup.sh script)"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "the name of the deploy pipeline to trigger (which must have"
  echo "  already been created with the build-deploy-setup.sh script)"
  echo "the stage predecessor collection (this is the OCID's of the preceeding"
  echo "  stage(s) recommend using the build-stage-predecessor.sh script and"
  echo "  then the build-items-array.sh to combine them"
  echo "  If there are no predecessors then the OCID of the pipeline itself"
  echo "  should be used"
  echo "Optional args"
  echo "  Description of the build pipeline (defaults to not provided)"  
  echo "  Pass build pipeline param to deploy stage (must be true or"
  echo "    false defaults to true)"  
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
DEVOPS_DEPLOY_PIPELINE_NAME="$4"
PREDECESSOR_STAGE_COLLECTION="$5"
if [ $# -ge 6 ]
then
  DEVOPS_BUILD_PIPELINE_DESCRIPTION="$6"
else
  DEVOPS_BUILD_PIPELINE_DESCRIPTION="Not Provided"
fi

if [ $# -ge 7 ]
then
  PASS_BUILD_PARAMS="$7"
else
  PASS_BUILD_PARAMS="true"
fi

if [ "$PASS_BUILD_PARAMS" != "true" ] && [ "$PASS_BUILD_PARAMS" != "false" ]
then
  echo "You must specify true or false for the pass pipeline params option, cannot continue"
  exit 1
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

# get the possible OCID for the devops project itself
echo "Getting var names for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID_NAME=`bash ./get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_OCID="${!DEVOPS_PROJECT_OCID_NAME}"
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "No ocid found for devops project $DEVOPS_PROJECT_NAME cannot continue. Has the project been created with the project-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops project $DEVOPS_PROJECT_NAME continuing"
fi

# get the possible  OCID for the devops build pipeline itself
echo "Getting var names for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME"
DEVOPS_BUILD_PIPELINE_OCID_NAME=`bash ./get-build-pipeline-ocid-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_OCID="${!DEVOPS_BUILD_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "No OCID found for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi

# get the possible  OCID for the devops deploy pipeline 
echo "Getting var names for devops deploy pipeline $DEVOPS_BUILD_PIPELINE_NAME"
DEVOPS_DEPLOY_PIPELINE_OCID_NAME=`bash ./get-deploy-pipeline-ocid-name.sh $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_PIPELINE_OCID="${!DEVOPS_DEPLOY_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_PIPELINE_OCID" ]
then
  echo "No OCID found for devops deploy pipeline $DEVOPS_DEPLOE_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi


echo "Getting var names for stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
BUILD_STAGE_OCID_NAME=`bash ./get-build-stage-ocid-name.sh $BUILD_STAGE_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
BUILD_STAGE_REUSED_NAME=`bash ./get-build-stage-reused-name.sh $BUILD_STAGE_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!BUILD_STAGE_REUSED_NAME}" ]
then
  echo "No reuse information found for build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME ,continuing"
else
  echo "Reuse information found for stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME has already been setup, to remove it use the build-stage-destroy.sh script"
  exit 0
fi

echo "Checking for build stage with existing name"
MATCHING_NAMES_COUNT=`oci devops build-pipeline-stage list --build-pipeline-id $DEVOPS_BUILD_PIPELINE_OCID --display-name "$BUILD_STAGE_NAME" --all | jq '.data.items | length'`
if [ $MATCHING_NAMES_COUNT -ne 0 ]
then
  echo "Found an existing stage with the name $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME cannot continue"
  exit 2
fi


echo "Creating devops trigger deploy stage $BUILD_STAGE_NAME in build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
BUILD_STAGE_OCID=`oci devops build-pipeline-stage create-trigger-deployment-stage --build-pipeline-id "$DEVOPS_BUILD_PIPELINE_OCID" --deploy-pipeline-id  "$DEVOPS_DEPLOY_PIPELINE_OCID" --display-name "$BUILD_STAGE_NAME" --stage-predecessor-collection  "$PREDECESSOR_STAGE_COLLECTION" --is-pass-all-parameters-enabled "$PASS_BUILD_PARAMS" --description "$DEVOPS_BUILD_PIPELINE_DESCRIPTION" | jq -r '.data.id'`
 
if [ -z "$BUILD_STAGE_OCID" ]
then
  echo "devops build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops build stage $BUILD_STAGE_NAME in devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
echo "$BUILD_STAGE_OCID_NAME=$BUILD_STAGE_OCID" >> $SETTINGS
echo "$BUILD_STAGE_REUSED_NAME=false" >> $SETTINGS