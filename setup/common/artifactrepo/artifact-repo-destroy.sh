#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument"
  echo "the name of the devops project to destroy"
  exit 1
fi

ARTIFACT_REPO_NAME=$1
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
echo "Getting var names for devops project $ARTIFACT_REPO_NAME"
ARTIFACT_REPO_OCID_NAME=`bash ./get-artifact-repo-ocid-name.sh $ARTIFACT_REPO_NAME`
ARTIFACT_REPO_REUSED_NAME=`bash ./get-artifact-repo-reused-name.sh $ARTIFACT_REPO_NAME`

if [ -z "${!ARTIFACT_REPO_REUSED_NAME}" ]
then
  echo "No reuse information for artifact repo $ARTIFACT_REPO_NAME , perhaps it's already been removed ? Cannot safely proceed with deleting artifact repo"
  exit 0
fi

if [ "${!ARTIFACT_REPO_REUSED_NAME}" = true ]
then
  echo "Cannot delete an artifact repo not created by these scripts, please delete the artifact repo by hand"
  exit 0
fi

if [ -z "${!ARTIFACT_REPO_OCID_NAME}" ]
then
  echo "No srtifact repo OCID information, cannot proceed"
  exit 0
fi

ARTIFACT_REPO_OCID="${!ARTIFACT_REPO_OCID_NAME}"
NON_DELETED_COUNT=`oci artifacts generic artifact list --compartment-id $COMPARTMENT_OCID --repository-id $ARTIFACT_REPO_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" != "DELETED")' | jq -s 'length'`

if ["$NON_DELETED_COUNT" != 0 ]
then
  echo "Artifact repo $ARTIFACT_REPO_NAME containes $NON_DELETED_COUNT artifacts that have not been deleted. It's not possible to delete a repo containing non deleted artifacts, cannot continue"
  exit 30
fi

echo "Deleting artifact repo $ARTIFACT_REPO_NAME"

oci artifacts repository delete --repository-id  $ARTIFACT_REPO_OCID --force  --wait-for-state "DELETED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $ARTIFACT_REPO_OCID_NAME
bash ../delete-from-saved-settings.sh $ARTIFACT_REPO_REUSED_NAME

