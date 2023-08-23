#!/bin/bash -f

REQUIRED_ARGS_COUNT=5
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops deploy artifact to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "The name of the artifact repo to be used (which must have been"
  echo "  setup using the artifactrepo/artifact-repo-generic-setup.sh script)"
  echo "The path within the artifact repo this is just a string (e.g. "
  echo "  storefront/config/deploy.properties) or can contain placeholders"
  echo '  from the pibeline (e.g. ${project}/config/deploy.properties which'
  echo "  will be substitued if praam substitution is SUBSTITUTE_PLACEHOLDERS"
  echo "  (the default) be careful about unix quoting here"
  echo "The version of the artifact in the OCIR repo this is just a string"
  echo ' (e.g. 1.0.1) or can contain placeholders e.g. ${version} which'
  echo "  will be substitued if praam substitution is SUBSTITUTE_PLACEHOLDERS"
  echo " (the default) be careful about unix quoting here"
  echo "Optional args"
  echo "  Description of the deploy artifact  (defaults to not provided)"
  echo "  Artifact type (COMMAND_SPEC, DEPLOYMENT_SPEC, DOCKER_IMAGE, GENERIC_FILE,"
  echo "    JOB_SPEC, KUBERNETES_MANIFEST, default so GENERIC_FILE)"
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
ARTIFACT_REPO_NAME=$3
ARTIFACT_PATH="$4"
ARTIFACT_VERSION="$5"
if [ $# -ge 6 ]
then
  DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION="$6"
else
  DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION="Not Provided"
fi
if [ $# -ge 7 ]
then
  ARTIFACT_TYPE="$7"
else
  ARTIFACT_TYPE="DOCKER_IMAGE"
fi
if [ "$ARTIFACT_TYPE" != "COMMAND_SPEC" ] && [ "$ARTIFACT_TYPE" != "DOCKER_IMAGE" ] && [ "$ARTIFACT_TYPE" != "GENERIC_FILE" ] && [ "$ARTIFACT_TYPE" != "JOB_SPEC" ] && [ "$ARTIFACT_TYPE" != "KUBERNETES_MANIFEST" ]
then
  echo "If provided you must specify DEPLOYMENT_SPEC, DOCKER_IMAGE, GENERIC_FILE, JOB_SPEC, KUBERNETES_MANIFEST for the artifact type option, cannot continue"
  exit 1
fi
if [ $# -ge 8 ]
then
  ALLOW_PARAM_SUBSTITUTION="$8"
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
echo "Getting OCID for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID_NAME=`bash ./get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_OCID="${!DEVOPS_PROJECT_OCID_NAME}"
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "No ocid found for devops project $DEVOPS_PROJECT_NAME cannot continue. Has the project been created with the project-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops project $DEVOPS_PROJECT_NAME continuing"
fi

# get the artifact repo details - note these are in a different folder so have to switch temporaraly
SAVED_DIR=`pwd`
cd ../artifactrepo*****
echo "Getting OCID for artifact repo $ARTIFACT_REPO_NAME"
ARTIFACT_REPO_OCID=`bash ./get-artifact-repo-ocid.sh $ARTIFACT_REPO_NAME`
if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "No ocid found for artifact repo $ARTIFACT_REPO_NAME cannot continue. Has the artifact been created with the artifact-repo-generic-setup.sh script ?"
  exit 1
else
  echo "Located the OCID for the artifact repo $ARTIFACT_REPO_NAME continuing"
fi
# got it, head back
cd $SAVED_DIR
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
MATCHING_NAMES_COUNT=`oci devops deploy-artifact list --project-id "$DEVOPS_PROJECT_OCID" --display-name "$DEPLOY_ARTIFACT_NAME" --lifecycle-state "ACTIVE" --all | jq '.data.items | length'`
if [ $MATCHING_NAMES_COUNT -ne 0 ]
then
  echo "Found an existing deploy artifact with the name $DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME cannot continue"
  exit 2
fi


echo "Creating devops generic deploy artifact $DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEPLOY_ARTIFACT_OCID=`oci devops deploy-artifact create-generic-artifact --argument-substitution-mode  "$ALLOW_PARAM_SUBSTITUTION" --artifact-path "$ARTIFACT_PATH" --artifact-type "$ARTIFACT_TYPE" --artifact-version "$ARTIFACT_VERSION" --project-id  "$DEVOPS_PROJECT_OCID" --repository-id "$ARTIFACT_REPO_OCID" --display-name "$DEPLOY_ARTIFACT_NAME"  --description "$DEVOPS_DEPLOY_ARTIFACT_DESCRIPTION" | jq -r '.data.id'`
 
if [ -z "$DEPLOY_ARTIFACT_OCID" ]
then
  echo "Failed to create devops generic deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME, unable to continue"
  exit 2
fi
echo "Created devops generic deploy artifact $DEPLOY_ARTIFACT_NAME in devops project $DEVOPS_PROJECT_NAME"
echo "$DEPLOY_ARTIFACT_OCID_NAME=$DEPLOY_ARTIFACT_OCID" >> $SETTINGS
echo "$DEPLOY_ARTIFACT_REUSED_NAME=false" >> $SETTINGS