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
CONFDIR=$HOME/helidon-kubernetes/configurations
LOGGERDIR=$CONFDIR/logger
echo Deleting existing logger config maps
echo logs-config-map
kubectl delete configmap logs-config-mapp --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo Non logger Config Maps remaining in namespace are 
kubectl get configmaps --context $CLUSTER_CONTEXT_NAME
echo Creating logger config maps
echo logs-config-map
kubectl create configmap logs-config-map --from-file=$LOGGERDIR/conf --context $CLUSTER_CONTEXT_NAME
echo Config maps incl logger in namespace are 
kubectl get configmaps --context $CLUSTER_CONTEXT_NAME

