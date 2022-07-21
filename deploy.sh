#!/bin/bash
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
echo Creating zipkin deployment
kubectl apply -f zipkin-deployment.yaml --record=true  --context $CLUSTER_CONTEXT_NAME
echo Creating stockmanager deployment
kubectl apply -f stockmanager-deployment.yaml --record=true --context $CLUSTER_CONTEXT_NAME
echo Creating storefront deployment
kubectl apply -f storefront-deployment.yaml --record=true --context $CLUSTER_CONTEXT_NAME
echo Kubenetes config is
kubectl get all --context $CLUSTER_CONTEXT_NAME
