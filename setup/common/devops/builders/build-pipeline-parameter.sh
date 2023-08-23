#!/bin/bash -f
# build indivdual params with this, then set up the array using the build-items-array.sh script
REQUIRED_ARGS_COUNT=2
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The name of the pipeline parameter"
  echo "The default value of the piupeline parameter"
  echo "Optionally"
  echo " The descriptio of the pipelikne parameter"
  exit -1
fi

PARAM_NAME=$1
PARAM_DEFAULT=$2
if [ $# -Gt $REQUIRED_ARGS_COUNT ]
then
  PARAM_DESCRIPTION=$3
else
  PARAM_DESCRIPTION="Not provided"
fi

echo "{\"name\":\"$PARAM_NAME\", \"defaultValue\":\"$PARAM_DEFAULT\", \"description\":\"$PARAM_DESCRIPTION\"}"