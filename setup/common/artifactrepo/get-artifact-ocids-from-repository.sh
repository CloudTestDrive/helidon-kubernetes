#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument:"
  echo "the name of the artifact to to create"
  echo "Optional args"
  echo "  artifact name (also known as artifact path)"
  echo "  artifact version"
  exit 1
fi

ARTIFACT_REPO_NAME=$1
ARTIFACT_PATH_PARAM=
if [ $# -ge 2 ]
then
  ARTIFACT_PATH_PARAM="--artifact-path $2"
fi
ARTIFACT_VERSION_PARAM=
if [ $# -ge 3 ]
then
  ARTIFACT_VERSION_PARAM="--artifact-version $3"
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

if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

ARTIFACT_REPO_OCID_NAME=`bash ./get-artifact-repo-ocid-name.sh $ARTIFACT_REPO_NAME`
ARTIFACT_REPO_OCID="${!ARTIFACT_REPO_OCID_NAME}"
if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "Cannot locate ocid for artifact repository $ARTIFACT_REPO_NAME it may not exist or have not been created by these scripts"
  exit 3
fi

oci artifacts generic artifact list --compartment-id $COMPARTMENT_OCID --repository-id $ARTIFACT_REPO_OCID $ARTIFACT_PATH_PARAM  $ARTIFACT_VERSION_PARAM | jq -r '.data.items[] | select (."lifecycle-state" != "DELETED") | .id'