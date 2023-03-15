#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument:"
  echo "the name of the artifact to to create"
  echo "Optional args"
  echo "  artifact name (also known as artifact path)"
  echo "  artifact version"
  exit 1
fi

ARTIFACT_REPO_NAME=$1
ARTIFACT_PATH_PARAM=
if [ $# -ge 2 ]
then
  ARTIFACT_PATH_PARAM=$2
fi
ARTIFACT_VERSION_PARAM=
if [ $# -ge 3 ]
then
  ARTIFACT_VERSION_PARAM="$3"
fi

OCIDS=`bash ./get-artifact-ocids-from-repository.sh $ARTIFACT_REPO_NAME $ARTIFACT_PATH_PARAM $ARTIFACT_VERSION_PARAM`

for OCID in "$OCIDS"
do
  echo "$Deleting artifact $OCID"
  bash ./artifact-delete-by-ocid.sh $OCID
done
