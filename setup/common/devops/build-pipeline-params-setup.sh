#!/bin/bash -f

REQUIRED_ARGS_COUNT=4
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The name of the pipeline"
  echo "The name of the devops project"
  echo "The items array of params (use the builders/build-pipeline-parameter.sh"
  echo "script to create the individual param entries then the build-items.sh"
  echo "script to combine them)"
  exit -1
fi
DEVOPS_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_PIPELINE_PARAMS=$3


PIPELINE_OCID=`bash ./get-build-pipeline-ocid.sh "$DEVOPS_PIPELINE_NAME" "$DEVOPS_PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact pipeline $DEVOPS_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit $RESP
fi

bash ./set-pipeline-params.sh BUILD "$PIPELINE_OCID" "$DEVOPS_PIPELINE_PARAMS"