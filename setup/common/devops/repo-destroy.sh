#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires two arguments"
  echo "the name of the devops repo to destroy"
  echo "the name of the containing devops project"
  exit 1
fi

DEVOPS_REPO_NAME=$1
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

# get the possible reuse and OCID for the devops repo itself
echo "Getting var names for devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
DEVOPS_REPO_OCID_NAME=`bash ./get-repo-ocid-name.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_REPO_REUSED_NAME=`bash ./get-repo-reused-name.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`

if [ -z "${!DEVOPS_REPO_REUSED_NAME}" ]
then
  echo "No reuse information for devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME, perhaps it's already been removed ? Cannot safely proceed with deleting repo"
  exit 0
fi

if [ "${!DEVOPS_REPO_REUSED_NAME}" = true ]
then
  echo "Cannot delete a devops repo not created by these scripts, please delete the repo by hand"
  bash ../delete-from-saved-settings.sh $DEVOPS_REPO_OCID_NAME
  bash ../delete-from-saved-settings.sh $DEVOPS_REPO_REUSED_NAME
  exit 0
fi
# Get the OCID for the repo
DEVOPS_REPO_OCID="${!DEVOPS_REPO_OCID_NAME}"
if [ -z "${!DEVOPS_REPO_OCID}" ]
then
  echo "No devops repo OCID information, cannot proceed"
  exit 0
fi


echo "Deleting devops repo $DEVOPS_REPO_NAME  in project $DEVOPS_PROJECT_NAME"

oci devops repository delete --repository-id  $DEVOPS_REPO_OCID --force --wait-for-state "SUCCEEDED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $DEVOPS_REPO_OCID_NAME
bash ../delete-from-saved-settings.sh $DEVOPS_REPO_REUSED_NAME

