#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
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

source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "Updating path for script"
export PATH=$PATH:$HOME/.linkerd2/bin

echo "Uninjecting linkerd from namespace ingress-nginx in cluster $CLUSTER_CONTEXT_NAME"
kubectl get namespace ingress-nginx --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd uninject - | kubectl replace --context $CLUSTER_CONTEXT_NAME -f -

echo "Uninjecting linkerd from namespace $NAMESPACE in cluster $CLUSTER_CONTEXT_NAME"
kubectl get namespace $NAMESPACE --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd uninject - | kubectl replace --context $CLUSTER_CONTEXT_NAME -f -

echo "Restarting the ingress contrtoller to remove it to the mesh in cluster $CLUSTER_CONTEXT_NAME"
kubectl rollout restart deployments --context $CLUSTER_CONTEXT_NAME -n ingress-nginx ingress-nginx-controller

echo "Restarting storefront, stockmanager and zipkin to remove them to the mesh in cluster $CLUSTER_CONTEXT_NAME"
kubectl rollout restart deployments storefront stockmanager zipkin --context $CLUSTER_CONTEXT_NAME

echo "Running main linkerd tidy up script in cluster $CLUSTER_CONTEXT_NAME"

SAVD_DIR=`pwd`
cd ../linkerd
bash ./linkerd-uninstall.sh $NAMESPACE autoconfirm

cd $HOME/helidon-kubernetes/service-mesh

echo "Removing the local files"
touch auth tls-ld.crt tls-ld.key
rm auth tls-*.crt tls-*.key

echo "Removing the modified ingress-rule file"
bash ./reset-ingress-ip.sh autoconfirm
