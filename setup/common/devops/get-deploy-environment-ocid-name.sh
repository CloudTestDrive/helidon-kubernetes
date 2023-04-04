#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the deploy environment to process and the name of the containg devops project"
  exit -1
fi
DEVOPS_DEPLOY_ENVIRONMENT_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_DEPLOY_ENVIRONMENT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_DEPLOY_ENVIRONMENT_NAME`
DEVOPS_PROJECT_NAME_CAPS=`bash ../settings/to-valid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_ENVIRONMENT_OCID_NAME=DEVOPS_DEPLOY_ENVIRONMENT_"$DEVOPS_DEPLOY_ENVIRONMENT_NAME_CAPS"_IN_PROJECT_"$DEVOPS_PROJECT_NAME_CAPS"_OCID
echo $DEVOPS_DEPLOY_ENVIRONMENT_OCID_NAME