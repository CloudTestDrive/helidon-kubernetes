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

echo "Updating the storefront config and restarting"
bash update-storefront-configmap.sh reset $CLUSTER_CONTEXT_NAME
# This assumes that the ingress rules and deployment have been updated
echo "Delete the ingress rule"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f ingressLoggerRules-"$CLUSTER_CONTEXT_NAME".yaml
echo "Delete the deployment"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f logger-deployment.yaml
echo "Delete logger service"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f serviceLogger.yaml
echo "Delete logger configmaps"
bash create-configmaps.sh $CLUSTER_CONTEXT_NAME
echo "Delete persistent volume for the logger"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f persistentVolumeClaim.yaml