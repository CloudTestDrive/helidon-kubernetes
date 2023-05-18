#!/bin/bash

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the External IP address of the ingress controler service"
    echo "Optional"
    echo "  2nd arg the name of the kubernrtes context"
    exit -1 
fi
EXTERNAL_IP=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
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
  echo "Auto confirm is enabled, Updating the ingress config to set $EXTERNAL_IP as the External IP address. defaulting to $REPLY"
else
  read -p "Updating the ingress config to set $EXTERNAL_IP as the External IP address. (y/n) ?" REPLY
fi 
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Updating the ingress config to set $EXTERNAL_IP as the External IP address.."
fi
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/set-ingress-config.sh $HOME/helidon-kubernetes/persistence $EXTERNAL_IP $CLUSTER_CONTEXT_NAME