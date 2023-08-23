#!/bin/bash -f

if [ $# -lt 3 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires three arguments"
  echo "the name of the deploy stage to process"
  echo "the name of the containing deploy pipeline"
  echo "the name of the containing devops project"
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
DEVOPS_DEPLOY_STAGE_NAME=$1
DEVOPS_DEPLOY_PIPELINE_NAME=$2
DEVOPS_PROJECT_NAME=$3
DEVOPS_DEPLOY_STAGE_OCID_NAME=`bash ./get-deploy-stage-ocid-name.sh $DEVOPS_DEPLOY_STAGE_NAME $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_STAGE_OCID="${!DEVOPS_DEPLOY_STAGE_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_STAGE_OCID" ]
then
  echo "Cannot locate OCID for devops deploy pipeline $DEVOPS_DEPLOY_STAGE_NAME in deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_DEPLOY_STAGE_OCID