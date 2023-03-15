#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the artifact repo to process"
  exit -1
fi
ARTIFACT_REPO_NAME=$1
ARTIFACT_REPO_NAME_CAPS=`bash ../settings/to-valid-name.sh $ARTIFACT_REPO_NAME`
ARTIFACT_REPO_REUSED_NAME=ARTIFACT_REPO_"$ARTIFACT_REPO_NAME_CAPS"_REUSED
echo $ARTIFACT_REPO_REUSED_NAME