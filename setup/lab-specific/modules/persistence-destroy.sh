#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings, cannot continue"
  exit 10
fi
if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME using provided cluster name of $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME using default cluster name of $CLUSTER_CONTEXT_NAME"
fi
SAVED_PWD=`pwd`
cd $PERSISTENCE_DIR
bash ./logger-microservice-destroy.sh $CLUSTER_CONTEXT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes persistence  destroyfor cluster $CLUSTER_CONTEXT_NAME returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
exit 0