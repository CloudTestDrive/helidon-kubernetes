#!/bin/bash -f
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
for INGRESS_FILE in $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules-$CLUSTER_CONTEXT_NAME.yaml 
do
   echo "Applying $INGRESS_FILE"
   kubectl apply -f $INGRESS_FILE  --context $CLUSTER_CONTEXT_NAME
done