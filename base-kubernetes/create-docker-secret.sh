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
echo Deleting existing docker secret
echo my-docker-reg
kubectl delete secret my-docker-reg --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo Creating docker secrets
echo my-docker-reg
kubectl create secret docker-registry my-docker-reg --docker-server=fra.ocir.io --docker-username='tenancy-object-storage-namespace/oracleidentitycloudservice/username' --docker-password='abcdefrghijklmnopqrstuvwxyz' --docker-email='you@email.com'  --context $CLUSTER_CONTEXT_NAME


