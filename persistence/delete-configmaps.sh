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
CONFDIR=$HOME/helidon-kubernetes/configurations
LOGGERDIR=$CONFDIR/logger
echo "Deleting existing logger config maps"
echo "logs-config-map"
kubectl delete configmap logs-config-map --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Non logger Config Maps remaining in namespace are "
kubectl get configmaps --context $CLUSTER_CONTEXT_NAME

