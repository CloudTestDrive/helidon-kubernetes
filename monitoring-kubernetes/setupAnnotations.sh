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
STOREFRONTPOD=`kubectl get pods -l "app=storefront" -o jsonpath="{.items[0].metadata.name}" --context $CLUSTER_CONTEXT_NAME`
echo "Storefront pod is $STOREFRONTPOD"
kubectl annotate pod $STOREFRONTPOD prometheus.io/scrape=true --overwrite --context $CLUSTER_CONTEXT_NAME
kubectl annotate pod $STOREFRONTPOD prometheus.io/path=/metrics --overwrite --context $CLUSTER_CONTEXT_NAME
kubectl annotate pod $STOREFRONTPOD prometheus.io/port=9080 --overwrite --context $CLUSTER_CONTEXT_NAME
echo "Storefront annotations are "
kubectl get pod $STOREFRONTPOD -o jsonpath="{.metadata..annotations}" --context $CLUSTER_CONTEXT_NAME
STOCKMANAGERPOD=`kubectl get pods -l "app=stockmanager" -o jsonpath="{.items[0].metadata.name}" --context $CLUSTER_CONTEXT_NAME`
echo "Stockmanager pod is $STOCKMANAGERPOD"
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/scrape=true --overwrite --context $CLUSTER_CONTEXT_NAME
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/path=/metrics --overwrite --context $CLUSTER_CONTEXT_NAME
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/port=9081 --overwrite --context $CLUSTER_CONTEXT_NAME
echo "Stockmanager annotations are "
kubectl get pod $STOCKMANAGERPOD -o jsonpath="{.metadata..annotations}" --context $CLUSTER_CONTEXT_NAME
