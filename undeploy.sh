#!/bin/bash
SCRIPT_NAME=`basename $0`

if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
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
echo Deleting storefront deployment
kubectl delete -f storefront-deployment.yaml --context $CLUSTER_CONTEXT_NAME
echo Deleting stockmanager deployment
kubectl delete -f stockmanager-deployment.yaml --context $CLUSTER_CONTEXT_NAME
echo Deleting zipkin deployment
kubectl delete -f zipkin-deployment.yaml --context $CLUSTER_CONTEXT_NAME
echo Kubenetes config is
kubectl get all
