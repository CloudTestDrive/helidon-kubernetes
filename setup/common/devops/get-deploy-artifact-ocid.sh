#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the deploy artifact to process and the name of the containing devops project"
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
DEVOPS_DEPLOY_ARTIFACT_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_DEPLOY_ARTIFACT_OCID_NAME=`bash ./get-deploy-artifact-ocid-name.sh $DEVOPS_DEPLOY_ARTIFACT_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_ARTIFACT_OCID="${!DEVOPS_DEPLOY_ARTIFACT_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_ARTIFACT_OCID" ]
then
  echo "Cannot locate OCID for devops deploy artifact $DEVOPS_DEPLOY_ARTIFACT_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_DEPLOY_ARTIFACT_OCID