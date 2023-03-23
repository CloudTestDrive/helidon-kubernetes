#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the trigger to process and the name of the containg devops project"
  exit -1
fi
DEVOPS_TRIGGER_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_TRIGGER_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_TRIGGER_NAME`
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_TRIGGER_REUSED_NAME=DEVOPS_TRIGGER_"$DEVOPS_TRIGGER_NAME_CAPS"_IN_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_REUSED
echo $DEVOPS_TRIGGER_REUSED_NAME