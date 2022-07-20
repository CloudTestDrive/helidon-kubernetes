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
MGRDIR=$CONFDIR/stockmanagerconf
FRONTDIR=$CONFDIR/storefrontconf
echo Deleting existing config maps
echo sf-config-map
kubectl delete configmap sf-config-map --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo sm-config-map
kubectl delete configmap sm-config-map --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo Config Maps remaining in namespace are 
kubectl get configmaps --context $CLUSTER_CONTEXT_NAME
echo Creating config maps
echo sf-config-map
kubectl create configmap sf-config-map --from-file=$FRONTDIR/conf --context $CLUSTER_CONTEXT_NAME
echo sm-config-map
kubectl create configmap sm-config-map --from-file=$MGRDIR/conf --context $CLUSTER_CONTEXT_NAME
echo Existing in namespace are 
kubectl get configmaps --context $CLUSTER_CONTEXT_NAME

