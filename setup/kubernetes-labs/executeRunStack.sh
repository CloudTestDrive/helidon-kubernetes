#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -lt 2 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo " 1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo " 2nd arg the ingress controller IP address"
    echo "Optional"
    echo " 3rd arg the name of the kubernrtes context - defaults to one"
    exit -1
fi
NAMESPACE=$1
EXTERNAL_IP=$2
CLUSTER_CONTEXT_NAME=one
if [ $# -ge 3 ]
then
  CLUSTER_CONTEXT_NAME=$3
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi


CLUSTER_SETTINGS_FILE=$HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, setting up config in downloaded git repo using $NAMESPACE as the department name $EXTERNAL_IP as ther ingress controller IP address $CLUSTER_CONTEXT_NAME is the current kubernetes context name default to $REPLY"
else
  echo "setting up config in downloaded git repo using $NAMESPACE as the department name $EXTERNAL_IP as ther ingress controller IP address $CLUSTER_CONTEXT_NAME is the current kubernetes context name"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Setting up config in downloaded git repo using $NAMESPACE as the department name $EXTERNAL_IP as the ingress controller IP address $CLUSTER_CONTEXT_NAME is the current kubernetes context name"
fi
cd $HOME/helidon-kubernetes/base-kubernetes
echo "Setup namespace"
bash ./create-namespace.sh $NAMESPACE $CLUSTER_CONTEXT_NAME
echo export NAMESPACE=$NAMESPACE >> $CLUSTER_SETTINGS_FILE
echo 'echo NAMESPACE is set to $NAMESPACE'  >> $CLUSTER_SETTINGS_FILE
echo "Creating tls store secret"
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/create-store-cert.sh $EXTERNAL_IP $CLUSTER_CONTEXT_NAME
bash ./create-services.sh $CLUSTER_CONTEXT_NAME
bash ./create-ingress-rules.sh $CLUSTER_CONTEXT_NAME
bash ./create-secrets.sh $CLUSTER_CONTEXT_NAME
bash ./create-configmaps.sh $CLUSTER_CONTEXT_NAME
cd ..
bash ./deploy.sh $CLUSTER_CONTEXT_NAME

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/waitForServicesByIP.sh $EXTERNAL_IP