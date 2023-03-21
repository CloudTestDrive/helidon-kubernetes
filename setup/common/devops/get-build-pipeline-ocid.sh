#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the build pipeline to process and the name of the containing devops project"
  exit -1
fi
if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
DEVOPS_BUILD_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_BUILD_PIPELINE_OCID_NAME=`bash ./get-build-pipeline-ocid-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_OCID="${!DEVOPS_BUILD_PIPELINE_OCID_NAME}"
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "Cannot locate OCID for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_BUILD_PIPELINE_OCID