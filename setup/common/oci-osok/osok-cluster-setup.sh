#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

bash ./operator-lifecycle-manager-setup.sh $CLUSTER_CONTEXT_NAME

RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Error installing lifecycle manager, cannot continue"
  exit $RESP
fi

bash ./osok-bundle-setup.sh $CLUSTER_CONTEXT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Error installing Oracle Service Operator for Kubernetes, cannot continue"
  exit $RESP
fi
exit 0