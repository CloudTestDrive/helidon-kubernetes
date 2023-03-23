#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the trigger to process and the name of the containing devops project"
  exit -1
fi
if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi
DEVOPS_TRIGGER_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_TRIGGER_OCID_NAME=`bash ./get-trigger-ocid-name.sh $DEVOPS_TRIGGER_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_TRIGGER_OCID="${!DEVOPS_TRIGGER_OCID_NAME}"
if [ -z "$DEVOPS_TRIGGER_OCID" ]
then
  echo "Cannot locate OCID for devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
  exit 1
fi
echo $DEVOPS_TRIGGER_OCID