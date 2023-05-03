#!/bin/bash -f

if [ $# -lt 3 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires three arguments"
  echo "the name of the build stage to process"
  echo "the name of the containing build pipeline"
  echo "the name of the containing devops project"
  exit -1
fi
DEVOPS_BUILD_STAGE_NAME=$1
DEVOPS_BUILD_PIPELINE_NAME=$2
DEVOPS_PROJECT_NAME=$3
DEVOPS_BUILD_STAGE_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_BUILD_STAGE_NAME`
DEVOPS_BUILD_PIPELINE_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_BUILD_PIPELINE_NAME`
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_STAGE_REUSED_NAME=DEVOPS_BUILD_STAGE_"$DEVOPS_BUILD_STAGE_NAME_CAPS"_IN_BUILD_PIPELINE_"$DEVOPS_BUILD_PIPELINE_NAME_CAPS"_IN_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_REUSED
echo $DEVOPS_BUILD_STAGE_REUSED_NAME