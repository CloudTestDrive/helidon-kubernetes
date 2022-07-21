#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your namespace - e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of the cluser context - defaults to one"
    exit -1 
fi
NAMESPACE=$1
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
SETTINGS_FILE=$HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
source $SETTINGS_FILE

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, About to remove existing stack in $NAMESPACE and reset ingress config and update cluster settings file $SETTINGS_FILE Kuberetes context is $CLUSTER_CONTEXT_NAME defaults to $REPLY"
else
  echo "About to remove existing stack in $NAMESPACE and reset ingress config and update cluster settings file $SETTINGS_FILE Kuberetes context is $CLUSTER_CONTEXT_NAME"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "About to remove existing stack in $NAMESPACE cluster settings file $SETTINGS_FILE Kuberetes context is $CLUSTER_CONTEXT_NAME"
fi
echo "Attempting to run linker removal script"
bash linkerd/linkerd-uninstall.sh $NAMESPACE $CLUSTER_CONTEXT_NAME
echo "deleting monitoring namespace - if present"
kubectl delete namespace monitoring --ignore-not-found=true  --context $CLUSTER_CONTEXT_NAME
echo "deleting logging namespace - if present"
kubectl delete namespace logging --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "deleting your existing deployments in $NAMESPACE"
kubectl delete namespace $NAMESPACE  --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "reseting to default namespace"
kubectl config set-context $CLUSTER_CONTEXT_NAME --namespace=default
echo "Blanking saved namespace"
echo NAMESPACE= >> $SETTINGS_FILE
echo "Tidying up security certificates and keys specific to $EXTERNAL_IP"
bash delete-certs.sh $EXTERNAL_IP 
