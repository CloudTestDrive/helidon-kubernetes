#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the devops project to process"
  exit -1
fi
DEVOPS_PROJECT_NAME=$1
DEVOPS_PROJECT_OCID_NAME=`bash get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_OCID="${!DEVOPS_PROJECT_OCID_NAME}"
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "Cannot locate OCID for devops project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_PROJECT_OCID