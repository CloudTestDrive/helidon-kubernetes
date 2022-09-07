#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME using provided cluster name of $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME using default cluster name of $CLUSTER_CONTEXT_NAME"
fi
SAVED_PWD=`pwd`
cd $PERSISTENCE_DIR
bash ./logger-microservice-setup.sh $CLUSTER_CONTEXT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes persistence setup for cluster $CLUSTER_CONTEXT_NAME returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
exit 0