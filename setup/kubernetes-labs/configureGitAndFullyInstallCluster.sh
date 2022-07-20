#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
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

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY=y
  echo "Auto confirm enabled, setting up config in downloaded git repo using $DEPARTMENT as the department and namespace name $CLUSTER_CONTEXT_NAME as the kubernetes context and $HOME/Wallet.zip as the DB wallet file. defaults to $REPLY"
else
  echo "setting up config in downloaded git repo using $DEPARTMENT as the department and namespace name $CLUSTER_CONTEXT_NAME as the kubernetes context and $HOME/Wallet.zip as the DB wallet file."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "OK, setting up config in downloaded git repo using $DEPARTMENT as the department and namespace name $CLUSTER_CONTEXT_NAME as the kubernetes context and $HOME/Wallet.zip as the DB wallet file."
fi

contextMatch=`kubectl config get-contexts --output=name | grep -w $CLUSTER_CONTEXT_NAME`

if [ -z $contextMatch ]
then
  echo "context $CLUSTER_CONTEXT_NAME not found, unable to continue"
  exit 2
else
  echo "Context $CLUSTER_CONTEXT_NAME found"
fi

echo "Configuring base location variables"
export LAB_LOCATION=$HOME/helidon-kubernetes
export LAB_SETUP_LOCATION=$LAB_LOCATION/setup
export KUBERNETES_SETUP_LOCATION=$LAB_SETUP_LOCATION/kubernetes-labs
echo Configuring helm
bash $KUBERNETES_SETUP_LOCATION/setupHelm.sh

echo "Saving current context of $startContext and switching to $CLUSTER_CONTEXT_NAME"

bash $KUBERNETES_SETUP_LOCATION/configure-downloaded-git-repo.sh $DEPARTMENT 

bash $KUBERNETES_SETUP_LOCATION/fullyInstallCluster.sh $DEPARTMENT $CLUSTER_CONTEXT_NAME


echo "Creating test data"
source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
bash $LAB_LOCATION/create-test-data.sh $EXTERNAL_IP
