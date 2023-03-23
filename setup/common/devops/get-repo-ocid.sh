#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the repo to process and the name of the containing devops project"
  exit -1
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
DEVOPS_REPO_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_REPO_OCID_NAME=`bash ./get-repo-ocid-name.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_REPO_OCID="${!DEVOPS_REPO_OCID_NAME}"
if [ -z "$DEVOPS_REPO_OCID" ]
then
  echo "Cannot locate OCID for devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_REPO_OCID