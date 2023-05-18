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
echo "Changing deployment CPU limits to 1 CPU"
kubectl patch deployment storefront --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"1000m"}]'  --context $CLUSTER_CONTEXT_NAME
kubectl patch deployment stockmanager --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"1000m"}]'  --context $CLUSTER_CONTEXT_NAME
