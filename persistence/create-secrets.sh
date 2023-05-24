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
echo "Deleting existing logger secrets"
echo "logs-conf-secure"
kubectl delete secret logs-conf-secure --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Deleted secrets"
echo "Non logger Secrets remaining in namespace are "
kubectl get secret --context $CLUSTER_CONTEXT_NAME
echo "Creating logger secrets"
kubectl create secret generic logs-conf-secure --from-file=$LOGGERDIR/confsecure --context $CLUSTER_CONTEXT_NAME
echo "Existing in namespace are "
kubectl get secrets --context $CLUSTER_CONTEXT_NAME

