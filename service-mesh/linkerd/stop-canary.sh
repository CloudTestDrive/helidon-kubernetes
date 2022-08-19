#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
kubectl delete -f stockmanager-deployment-v0.0.2.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f stockmanager-canary-traffic-split.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f ingressStockmanagerCanaryRules.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f stockmanager-v0.0.2-service.yaml  --context $CLUSTER_CONTEXT_NAME
kubectl delete -f stockmanager-v0.0.1-service.yaml  --context $CLUSTER_CONTEXT_NAME
