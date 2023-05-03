#!/bin/bash -f

if [ $# -lt 3 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires four arguments"
  echo "the name of the code repo to use as the build source"
  echo "  which must have been created by these scripts"
  echo "the name of the containing devops project"
  echo "  which must have been created by these scripts"
  echo "the branch in the code repo"
  exit -1
fi

REPO_NAME=$1
PROJECT_NAME=$2
REPO_BRANCH=$3

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

REPO_OCID_NAME=`bash ./get-repo-ocid-name.sh $REPO_NAME $PROJECT_NAME`
REPO_OCID="${!REPO_OCID_NAME}"
if [ -z "$REPO_OCID" ]
then
  echo "Cannot locate the OCID for repo $REPO_NAME in devops project $PROJECT_NAME cannot continue"
  exit 1
fi

REPO_URL_HTTPS=`oci devops repository get --repository-id "$REPO_OCID" | jq -j '.data."http-url"'`
bash ./builders/build-source-devops-code-repo.sh "$REPO_OCID" "$REPO_NAME" "$REPO_URL_HTTPS" "$REPO_BRANCH"