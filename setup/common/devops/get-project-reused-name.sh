#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the devops project to process"
  exit -1
fi
DEVOPS_PROJECT_NAME=$1
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_REUSED_NAME=DEVOPS_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_REUSED
echo $DEVOPS_PROJECT_REUSED_NAME