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

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

CONTEXT_MATCH=`kubectl config get-contexts --output=name  | grep -w $CLUSTER_CONTEXT_NAME `

if [ -z $CONTEXT_MATCH ]
  then
    echo "context $CLUSTER_CONTEXT_NAME not found in Kubernetes configuration, unable to continue"
    exit 2
  else
    echo "Context $CLUSTER_CONTEXT_NAME exists in Kubernetes configuration file"
fi

SETTINGS_FILE=$HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

if [ -f $SETTINGS_FILE ]
then
  source $SETTINGS_FILE
  echo "Located setings, using namespace $NAMESPACE"
else 
  echo "Unable to locate settings file $SETTINGS_FILE cannot continue"
  exit 1
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Using context $CLUSTER_CONTEXT_NAME About to destroy existing instalation in $NAMESPACE, and remove the ingress controller and dashboard defaults to $REPLY"
else
  echo "Using context $CLUSTER_CONTEXT_NAME About to destroy existing instalation in $NAMESPACE, and remove the ingress controller and dashboard"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else 
  echo "Using context $CLUSTER_CONTEXT_NAME About to destroy existing instalation in $NAMESPACE, and remove the ingress controller and dashboard"
fi

echo "Configuring base location variables"
export LAB_LOCATION=$HOME/helidon-kubernetes
export LAB_SETUP_LOCATION=$LAB_LOCATION/setup
export KUBERNETES_SETUP_LOCATION=$LAB_SETUP_LOCATION/kubernetes-labs

bash $KUBERNETES_SETUP_LOCATION/teardownStack.sh $NAMESPACE $CLUSTER_CONTEXT_NAME
bash $KUBERNETES_SETUP_LOCATION/removeBaseElements.sh $CLUSTER_CONTEXT_NAME


bash $KUBERNETES_SETUP_LOCATION/unconfigure-downloaded-git-repo.sh $NAMESPACE skip

