#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the artifact repo to process"
  exit -1
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
ARTIFACT_REPO_NAME=$1
ARTIFACT_REPO_OCID_NAME=`bash get-artifact-repo-ocid-name.sh $ARTIFACT_REPO_NAME`
ARTIFACT_REPO_OCID="${!ARTIFACT_REPO_OCID_NAME}"
if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "Cannot locate OCID for artifact repo $ARTIFACT_REPO_NAME"
  exit 1
fi
echo $ARTIFACT_REPO_OCID