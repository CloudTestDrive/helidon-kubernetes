#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of the cluster context to install into - defaults to one"
    exit -1
fi
DEPARTMENT=$1
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, setting up config in downloaded git repo using $DEPARTMENT as the department name $CLUSTER_CONTEXT_NAME is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file defaults to $REPLY"
else  
  echo "setting up config in downloaded git repo using $DEPARTMENT as the department name $CLUSTER_CONTEXT_NAME is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Will setup using  $DEPARTMENT as the department name $CLUSTER_CONTEXT_NAME is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file"
fi

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/installBaseElements.sh $CLUSTER_CONTEXT_NAME

source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/executeRunStack.sh $DEPARTMENT $EXTERNAL_IP $CLUSTER_CONTEXT_NAME