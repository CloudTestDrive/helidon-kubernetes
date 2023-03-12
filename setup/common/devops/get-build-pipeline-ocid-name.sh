#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the build pipeling to process and the name of the containg devops project"
  exit -1
fi
DEVOPS_BUILD_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_BUILD_PIPELINE_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_BUILD_PIPELINE_NAME`
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_OCID_NAME=DEVOPS_BUILD_PIPELINE_"$DEVOPS_BUILD_PIPELINE_NAME_CAPS"_IN_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_OCID
echo $DEVOPS_BUILD_PIPELINE_OCID_NAME