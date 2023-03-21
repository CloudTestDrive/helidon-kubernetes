#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the deploy pipeline to process and the name of the containing devops project"
  exit -1
fi
if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
DEVOPS_DEPLOY_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_DEPLOY_PIPELINE_OCID_NAME=`bash ./get-deploy-pipeline-ocid-name.sh $DEVOPS_DEPLOY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_PIPELINE_OCID="${!DEVOPS_DEPLOY_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_DEPLOY_PIPELINE_OCID" ]
then
  echo "Cannot locate OCID for devops deploy pipeline $DEVOPS_DEPLOY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_DEPLOY_PIPELINE_OCID