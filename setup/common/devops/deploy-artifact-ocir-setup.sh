#!/bin/bash -f

REQUIRED_ARGS_COUNT=3
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy artifact to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "the URI used to store / access the artifact in the OCIR repo"
  echo '  this can contain placeholders e.g. ${version} which will be substitued'
  echo "  if praam substitution is SUBSTITUTE_PLACEHOLDERS (the default) be careful about unix quoting here"
  echo "Optional args"
  echo "  Description of the deploy artifact  (defaults to not provided)"
  echo "  Artifact type (DEPLOYMENT_SPEC, DOCKER_IMAGE, GENERIC_FILE, JOB_SPEC"
  echo "    , KUBERNETES_MANIFEST, default to DOCKER_IMAGE"
  echo "  Parameter substitution mode (SUBSTITUTE_PLACEHOLDERS or NONE"
  echo "    defaults to SUBSTITUTE_PLACEHOLDERS)"
  
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

DEPLOY_ARTIFACT_NAME=$1
DEVOPS_PROJECT_NAME=$2
OCIR_SOURCE_URI="$3"
if [ $# -ge 4 ]
then
  DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION="$4"
else
  DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION="Not Provided"
fi
if [ $# -ge 5 ]
then
  ARTIFACT_TYPE="$5"
else
  ARTIFACT_TYPE="DOCKER_IMAGE"
fi
if [ "$ARTIFACT_TYPE" != "DEPLOYMENT_SPEC" ] && [ "$ARTIFACT_TYPE" != "DOCKER_IMAGE" ] && [ "$ARTIFACT_TYPE" != "GENERIC_FILE" ] && [ "$ARTIFACT_TYPE" != "JOB_SPEC" ] && [ "$ARTIFACT_TYPE" != "KUBERNETES_MANIFEST" ]
then
  echo "If provided you must specify DEPLOYMENT_SPEC, DOCKER_IMAGE, GENERIC_FILE, JOB_SPEC, KUBERNETES_MANIFEST for the artifact type option, cannot continue"
  exit 1
fi
if [ $# -ge 6 ]
then
  ALLOW_PARAM_SUBSTITUTION="$6"
else
  ALLOW_PARAM_SUBSTITUTION="SUBSTITUTE_PLACEHOLDERS"
fi

if [ "$ALLOW_PARAM_SUBSTITUTION" != "SUBSTITUTE_PLACEHOLDERS" ] && [ "$ALLOW_PARAM_SUBSTITUTION" != "NONE" ]
then
  echo "If provided you must specify SUBSTITUTE_PLACEHOLDERS or NONE for the allow param substitution option, cannot continue"
  exit 1
fi

if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
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

echo "Getting var names for deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
DEPLOY_ARTIFACT_OCID_NAME=`bash ./get-deploy-artifact-ocid-name.sh $DEPLOY_ARTIFACT_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEPLOY_ARTIFACT_REUSED_NAME=`bash ./get-deploy-artifact-reused-name.sh $DEPLOY_ARTIFACT_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEPLOY_ARTIFACT_REUSED_NAME}" ]
then
  echo "No reuse information found for deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME ,continuing"
else
  echo "Reuse information found for deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME has already been setup, to remove it use the build-stage-destroy.sh script"
  exit 0
fi
echo "Checking for deploy artifact with existing name"
MATCHING_ARTIFACTS=`oci devops deploy-artifact list --project-id "$DEVOPS_PROJECT_OCID" --display-name "$DEPLOY_ARTIFACT_NAME" --lifecycle-state "ACTIVE" --all `
MATCHING_ARTIFACTS_COUNT=`echo "$MATCHING_ARTIFACTS" | jq '.data.items | length'`
if [ "$MATCHING_ARTIFACTS_COUNT" -gt 0 ]
then
  DEPLOY_ARTIFACT_OCID=`echo "$MATCHING_ARTIFACTS" | jq '.data.items[0].id'`
fi
if [ -z "$DEPLOY_ARTIFACT_OCID" ]
then
  echo "Creating devops OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME"
  # if waiting for state this returns the work request details (that's what we are actually waiting
  # on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
  DEPLOY_ARTIFACT_OCID=`oci devops deploy-artifact create-ocir-artifact --argument-substitution-mode  "$ALLOW_PARAM_SUBSTITUTION" --artifact-type "$ARTIFACT_TYPE" --project-id  "$DEVOPS_PROJECT_OCID" --display-name "$DEPLOY_ARTIFACT_NAME" --source-image-uri "$OCIR_SOURCE_URI" --description "$DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION" | jq -r '.data.id'`
  if [ -z "$DEPLOY_ARTIFACT_OCID" ]
  then
    echo "devops deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME, unable to continue"
    exit 2
  fi
  echo "Created devops deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
  echo "$DEPLOY_ARTIFACT_OCID_NAME=$DEPLOY_ARTIFACT_OCID" >> $SETTINGS
  echo "$DEPLOY_ARTIFACT_REUSED_NAME=false" >> $SETTINGS
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
    exit 1
  else
    echo "OK, will reuse existing devops OCIR deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
    echo "$DEPLOY_ARTIFACT_OCID_NAME=$DEPLOY_ARTIFACT_OCID" >> $SETTINGS
    echo "$DEPLOY_ARTIFACT_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi

