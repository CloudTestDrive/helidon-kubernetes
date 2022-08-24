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
kubectl delete -f fault-injector-traffic-split.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f ingressFaultInjectorRules.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f ../fault-injector-service.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f ../nginx-fault-injector-deployment.yaml --context $CLUSTER_CONTEXT_NAME
kubectl delete -f ../nginx-fault-injector-configmap.yaml --context $CLUSTER_CONTEXT_NAME