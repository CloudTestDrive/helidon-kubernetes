#!/bin/bash -f

REQUIRED_ARGS_COUNT=6
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy stage to to create"
  echo "the name of the containing deploy pipeline (which must have"
  echo "  already been created with the deploy-pipeline-setup.sh script)"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "the deploy artifacts collection (recommend creating these using the"
  echo "  build-strings-array.sh script to combine them)"
  echo "The name of the target environment (which must have been created using"
  echo "  an environment setup script"
  echo "the stage predecessor collection (this is the OCID's of the preceeding"
  echo "  stage(s) recommend using the builders/build-stage-predecessor.sh script and"
  echo "  then the build-items-array.sh to combine them"
  echo "  If there are no predecessors then the OCID of the pipeline itself"
  echo "  should be used"
  echo "Optional args"
  echo "  Description of the deploy stage (defaults to not provided)"
  
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
DEPLOY_ARTIFACTS_COLLECTION="$4"
DEPLOY_ENVIRONMENT_NAME="$5"
PREDECESSOR_STAGE_COLLECTION="$6"
if [ $# -ge $REQUIRED_ARGS_COUNT ]
then
  DEVOPS_DEPLOY_STAGE_DESCRIPTION="$7"
else
  DEVOPS_DEPLOY_STAGE_DESCRIPTION="Not Provided"
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

# get the possible reuse and OCID for the devops deploy pipeline itself
echo "Getting var names for devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME"
DEVOPS_DEPLOY_PIPELINE_OCID_NAME=`bash ./get-deploy-pipeline-ocid-name.sh $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_PIPELINE_OCID="${!DEVOPS_DEPLOY_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_PIPELINE_OCID" ]
then
  echo "No OCID found for devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi

echo "Getting OCID for deploy environment $DEPLOY_ENVIRONMENT_NAME"
DEPLOY_ENVIRONMENT_OCID=`bash ./get-deploy-environment-ocid.sh "$DEPLOY_ENVIRONMENT_NAME" "$DEVOPS_PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting deploy environment ocid for $DEPLOY_ENVIRONMENT_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi

echo "Getting var names for stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
DEPLOY_STAGE_OCID_NAME=`bash ./get-deploy-stage-ocid-name.sh $DEPLOY_STAGE_NAME $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEPLOY_STAGE_REUSED_NAME=`bash ./get-deploy-stage-reused-name.sh $DEPLOY_STAGE_NAME $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEPLOY_STAGE_REUSED_NAME}" ]
then
  echo "No reuse information found for deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME ,continuing"
else
  echo "Reuse information found for stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME has already been setup, to remove it use the deploy-stage-destroy.sh script"
  exit 0
fi

echo "Checking for deploy stage with existing name"
MATCHING_STAGES=`oci devops deploy-stage list --pipeline-id $DEVOPS_DEPLOY_PIPELINE_OCID --display-name "$DEPLOY_STAGE_NAME" --all `
MATCHING_STAGES_COUNT=`echo "$MATCHING_STAGES" | jq '.data.items | length'`
if [ "$MATCHING_STAGES_COUNT" -gt 0 ]
then
  DEPLOY_STAGE_OCID=`echo "$MATCHING_STAGES" | jq '.data.items[0].id'`
fi
if [ -z "$DEPLOY_STAGE_OCID" ]
then
  echo "Creating devops deploy to oke stage $DEPLOY_STAGE_NAME in deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  # if waiting for state this returns the work request details (that's what we are actually waiting
  # on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
  DEPLOY_STAGE_OCID=`oci devops deploy-stage create-deploy-oke-stage  --kubernetes-manifest-artifact-ids "$DEPLOY_ARTIFACTS_COLLECTION" --oke-cluster-environment-id "$DEPLOY_ENVIRONMENT_OCID" --pipeline-id "$DEVOPS_DEPLOY_PIPELINE_OCID" --display-name "$DEPLOY_STAGE_NAME" --stage-predecessor-collection  "$PREDECESSOR_STAGE_COLLECTION" --description "$DEVOPS_DEPLOY_PIPELINE_DESCRIPTION" | jq -r '.data.id'`
  if [ -z "$DEPLOY_STAGE_OCID" ]
  then
    echo "devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
    exit 2
  fi
  echo "Created devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  echo "$DEPLOY_STAGE_OCID_NAME=$DEPLOY_STAGE_OCID" >> $SETTINGS
  echo "$DEPLOY_STAGE_REUSED_NAME=false" >> $SETTINGS
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the deploy stage $DEPLOY_STAGE_NAME in devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
    exit 1
  else
    echo "OK, will reuse existing devops OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
  echo "$DEPLOY_STAGE_OCID_NAME=$DEPLOY_STAGE_OCID" >> $SETTINGS
  echo "$DEPLOY_STAGE_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi