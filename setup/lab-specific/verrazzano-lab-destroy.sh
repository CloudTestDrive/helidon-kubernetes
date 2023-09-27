#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

echo "This script will destroy the verrazano configuration in cluster $CLUSTER_CONTEXT_NAME"

SAVED_DIR=`pwd`
cd $MODULES_DIR
bash ./verrazzano-destroy-module.sh $CLUSTER_CONTEXT_NAME
cd $SAVED_DIR

read -p "Do you want to destroy the underlyign cluster and servcies (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   echo "OK, retaining underlying cluster"
else
  echo "This script uses the kubernetes labs destroy script so it will now perform those functions, you will need to respond to it's prompts"
  bash ./core-kubernetes-lab-destroy.sh $CLUSTER_CONTEXT_NAME
fi