#!/bin/bash -f
REQUIRED_ARGS_COUNT=1
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The OCID of the prior build stage or the build pipeline "
  echo "  OCID if this is to be the first stage in the pipeline"
  exit -1
fi

STAGE_OCID=$1

echo "{\"id\":\"$STAGE_OCID\"}"