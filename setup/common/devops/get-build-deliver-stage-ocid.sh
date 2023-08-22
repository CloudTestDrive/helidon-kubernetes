#!/bin/bash -f

if [ $# -lt 3 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires three arguments"
  echo "the name of the build deliver stage to process"
  echo "the name of the containing build pipeline"
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
DEVOPS_BUILD_DELIVER_STAGE_NAME=$1
DEVOPS_BUILD_PIPELINE_NAME=$2
DEVOPS_PROJECT_NAME=$3
DEVOPS_BUILD_DELIVER_STAGE_OCID_NAME=`bash ./get-build-deliver-stage-ocid-name.sh $DEVOPS_BUILD_DELIVER_STAGE_NAME $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_DELIVER_STAGE_OCID="${!DEVOPS_BUILD_DELIVER_STAGE_OCID_NAME}"
if [ -z "$DEVOPS_BUILD_DELIVER_STAGE_OCID" ]
then
  echo "Cannot locate OCID for devops build deliver stage $DEVOPS_BUILD_DELIVER_STAGE_NAME in build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_BUILD_DELIVER_STAGE_OCID