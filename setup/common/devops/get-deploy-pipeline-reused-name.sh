#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the deploy pipeline to process and the name of the containg devops project"
  exit -1
fi
DEVOPS_DEPLOPY_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_DEPLOPY_PIPELINE_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_DEPLOPY_PIPELINE_NAME`
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOPY_PIPELINE_REUSED_NAME=DEVOPS_DEPLOPY_PIPELINE_"$DEVOPS_DEPLOPY_PIPELINE_NAME_CAPS"_IN_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_REUSED
echo $DEVOPS_DEPLOPY_PIPELINE_REUSED_NAME