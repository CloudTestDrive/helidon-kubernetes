#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the ocir repo to process"
  exit -1
fi
if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
OCIR_REPO_NAME=$1
OCIR_REPO_OCID_NAME=`bash get-ocir-ocid-name.sh $OCIR_REPO_NAME`
OCIR_REPO_OCID="${!OCIR_REPO_OCID_NAME}"
if [ -z "$OCIR_REPO_OCID" ]
then
  echo "Cannot locate OCID for ocir repot $OCIR_REPO_NAME"
  exit 1
fi
echo $OCIR_REPO_OCID