#!/bin/bash -f

REQUIRED_ARGS_COUNT=3
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The type of pipeine (BUILD or DEPLOY)"
  echo "The OCID of the pipeline"
  echo "The items array of params (use the builders/pipeline-parameter.sh"
  echo "script to create the individual param entrues then the build-items.sh"
  echo "script to combine them)"
  exit -1
fi
DEVOPS_PIPELINE_TYPE=$1
DEVOPS_PIPELINE_OCID=$2
DEVOPS_PIPELINE_PARAMS=$3

if [ "$DEVOPS_PIPELINE_TYPE" != "BUILD" ] && [ "$DEVOPS_PIPELINE_TYPE" != "DEPLOY" ]
then
  echo "You must specify BUILD or DEPLOY for the pipeline type option, cannot continue"
  exit 1
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ "$DEVOPS_PIPELINE_TYPE" == "BUILD" ]
then
  PIPELINE_COMMAND="build-pipeline"
  PIPELINE_OCID_FLAG="--build-pipeline-id"
  PARAMS_FLAG="--build-pipeline-parameters"
else
  PIPELINE_COMMAND="deploy-pipeline"
  PIPELINE_OCID_FLAG="--pipeline-id"
  PARAMS_FLAG="--pipeline-parameters"
fi

echo "Setting pipeline params using command"
echo oci devops "$PIPELINE_COMMAND" update "$PIPELINE_OCID_FLAG" "$DEVOPS_PIPELINE_OCID" "$PARAMS_FLAG" "$DEVOPS_PIPELINE_PARAMS"
oci devops "$PIPELINE_COMMAND" update "$PIPELINE_OCID_FLAG" "$DEVOPS_PIPELINE_OCID" "$PARAMS_FLAG" "$DEVOPS_PIPELINE_PARAMS"