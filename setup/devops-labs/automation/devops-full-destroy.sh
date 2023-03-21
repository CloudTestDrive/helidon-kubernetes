#!/bin/bash -f

CLUSTER_CONTEXT=one
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT=$1
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 3
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Have you manually destroyed any devops items in your project not created by the devops-full-setup.sh script ? defaulting to $REPLY"
else
  read -p "Have you manually destroyed any devops items in your project not created by the devops-full-setup.sh script ? (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit, please destroy these items then you can re-run the script."
  exit -1
fi
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Ready to tear down the devops stack created by the devops-full-setup.sh script ? defaulting to $REPLY"
else
  read -p "Ready to tear down the devops stack created by the devops-full-setup.sh script ? (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit"
  exit -1
fi
ITEM_NAMES_FILE=names.sh
if [ -f "$ITEM_NAMES_FILE" ]
then
  echo "Located the names file $ITEM_NAMES_FILE, loading it"
  source $ITEM_NAMES_FILE
else
  echo "Unable to locate the names file $ITEM_NAMES_FILE this means the script will now have any of the names to process, cannot continue"
  exit 7
fi

echo "Passed checks starting to create environment"

SAVED_DIR=`pwd`
COMMON_DIR=`pwd`/../../common
DEVOPS_LAB_DIR=$SAVED_DIR/..

echo "This script attempts to follow the reverse order of the dev-ops lab"

echo "Destroying deploy pipeline"
cd $COMMON/devops
bash ./deploy-pipeline-destroy.sh $DEPLOY_PIPELINE_NAME $PROJECT_NAME 
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying deploy pipeline $DEPLOY_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi

echo "Destroying artifacts in artifact repo"
cd $COMMON/artifactrepo

bash ./artifact-delete.sh $ARTIFACT_REPO_NAME
echo "Destroying artifact repo"

bash ./artifact-repo-destroy.sh $ARTIFACT_REPO_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying artifact repo $ARTIFACT_REPO_NAME, unable to continue"
  exit $RESP
fi

echo "Destroying OCIR repo"
cd $COMMON/ocir
bash  ./ocir-destroy.sh $OCIR_REPO_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying OCIR repo $OCIR_REPO_NAME, unable to continue"
  exit $RESP
fi

echo "Destroying build pipeline"
cd $COMMON/devops
bash ./build-pipeline-destroy.sh $BUILD_PIPELINE_NAME $PROJECT_NAME 
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying build pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
cd $DEVOPS_LAB_DIR
echo "Destroying up vault secrets"
bash ./vault-secrets-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying vault secrets, unable to continue"
  exit $RESP
fi
echo "Destroy local code repo"
rm -rf $CODE_BASE

cd $COMMON_DIR/devops
echo "Destroy code repo"
bash ./repo-destroy.sh $CODE_REPO_NAME $PROJECT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying code repo, unable to continue"
  exit $RESP
fi

echo "Removing project logging"

cd $COMMON_DIR/logging
echo "Destroy log "
bash ./log-destroy.sh $LOG_NAME $LOG_GROUP_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying log , unable to continue"
  exit $RESP
fi
echo "Destroying log group"
bash ./log-group-destroy.sh $LOG_GROUP_NAME 
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying log group, unable to continue"
  exit $RESP
fi

echo "Destroy project"
cd $SAVED_DIR
cd $COMMON_DIR/devops
bash ./project-destroy.sh $PROJECT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps project destroy module returned an error, unable to continue"
  exit $RESP
fi

echo "Destroy notifications topic"
cd $COMMON_DIR/notifications
bash ./topic-destroy.sh "$TOPIC_NAME" 
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Topic destroy module returned an error, unable to continue"
  exit $RESP
fi