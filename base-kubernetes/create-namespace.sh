#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one
if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME missing arguments, you must provide:"
  echo "  1st arg namespace name to create and set as the default"
  echo "Optional"
  echo "  2nd arg the name of the kubernetes context to work on - default to one"
  exit -1
fi
NAMESPACE=$1
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

echo "Deleting old $NAMESPACE namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl delete namespace $NAMESPACE --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Creating new $NAMESPACE namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl create namespace $NAMESPACE --context $CLUSTER_CONTEXT_NAME
echo "Setting default kubectl namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl config set-context $CLUSTER_CONTEXT_NAME --namespace=$NAMESPACE