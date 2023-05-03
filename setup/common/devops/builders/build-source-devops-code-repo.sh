#!/bin/bash -f

REQUIRED_ARGS_COUNT=4
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "The OCID of the devops service code repo"
  echo "the name of the code repo to use as the build source"
  echo "the URL of the code repo"
  echo "the branch in the code repo"
  exit -1
fi

REPO_OCID=$1
BUILD_SOURCE_NAME=$2
REPO_URL=$3
REPO_BRANCH=$4
BUILD_SOURCE_TYPE="DEVOPS_CODE_REPOSITORY"

echo "{\"connectionType\":\"$BUILD_SOURCE_TYPE\",\"name\":\"$BUILD_SOURCE_NAME\", \"repositoryId\":\"$REPO_OCID\",\"repositoryUrl\":\"$REPO_URL\",\"branch\":\"$REPO_BRANCH\"}"