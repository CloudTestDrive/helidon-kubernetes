#!/bin/bash -f
REQUIRED_ARGS_COUNT=2
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The OCID of the artifact target (to deliver the artifact to)"
  echo "The name of the artifact source(as per the build spec)"
  exit -1
fi

DELIVERY_ARTIFACT_OCID=$1
SOURCE_ARTIFACT_NAME=$2

echo "{\"artifactId\":\"$DELIVERY_ARTIFACT_OCID\", \"artifactName\":\"$SOURCE_ARTIFACT_NAME\"}"