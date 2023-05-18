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
echo "Creating prometheus loadbalancer service"
kubectl apply -f servicesLoadBalancer.yaml --context $CLUSTER_CONTEXT_NAME
echo "Services are "
kubectl get services -n monitoring --context $CLUSTER_CONTEXT_NAME
