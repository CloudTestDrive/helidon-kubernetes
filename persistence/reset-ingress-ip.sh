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


if [ -z $"AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Updating the ingress config to remove templated files defaulting to $REPLY"
else
  read -p "Updating the ingress config to remove templated files (y/n) ?" REPLY
fi 
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Updating the ingress config to remove templated files."
fi
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/reset-ingress-config.sh $HOME/helidon-kubernetes/persistence $CLUSTER_CONTEXT_NAME