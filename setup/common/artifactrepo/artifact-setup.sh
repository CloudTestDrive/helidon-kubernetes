#!/bin/bash -f

if [ $# -lt 4 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument"
  echo "the name of the artifact repository to delete from"
  echo "the artifact name (also known as the artifact path, this does not include the version number)"
  echo "the artifact version"
  echo "the local path to upload"
  exit 1
fi

ARTIFACT_REPO_NAME=$1
ARTIFACT_PATH=$2
ARTIFACT_VERSION=$3
FILE_TO_UPLOAD=$4
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

# get the OCID for the repo itself
echo "Getting var names for devops project $ARTIFACT_REPO_NAME"
ARTIFACT_REPO_OCID_NAME=`bash ./get-artifact-repo-ocid-name.sh $ARTIFACT_REPO_NAME`

ARTIFACT_REPO_OCID="${!ARTIFACT_REPO_OCID_NAME}"

if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "No artifact repo OCID information found, has it been created by these scripts ?, cannot proceed"
  exit 0
fi

 if [ -r "$FILE_TO_UPLOAD" ]
 then
   echo "File readable"
 else
   echo "Cannot read $FILE_TO_UPLOAD to upload"
   exit 10
 fi
oci artifacts generic artifact upload-by-path --repository-id "$ARTIFACT_REPO_OCID" --artifact-path "$ARTIFACT_PATH" --artifact-version "$ARTIFACT_VERSION" --content-body "$FILE_TO_UPLOAD"
