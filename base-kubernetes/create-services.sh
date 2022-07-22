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
echo "Deleting existing services"
echo "Storefront"
kubectl delete service storefront --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Stockmanager"
kubectl delete service stockmanager --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Zipkin"
kubectl delete service zipkin --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Deleted services"
echo "Services remaining in namespace are "
kubectl get services --context $CLUSTER_CONTEXT_NAME
echo "Creating services"
echo "Zipkin"
kubectl apply -f serviceZipkin.yaml --context $CLUSTER_CONTEXT_NAME
echo "Stockmanager"
kubectl apply -f serviceStockmanager.yaml --context $CLUSTER_CONTEXT_NAME
echo "Storefront"
kubectl apply -f serviceStorefront.yaml --context $CLUSTER_CONTEXT_NAME
echo "Current services in namespace are "
kubectl get services --context $CLUSTER_CONTEXT_NAME

