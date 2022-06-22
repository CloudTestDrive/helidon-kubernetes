#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi


source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "Updating path for script"
export PATH=$PATH:$HOME/.linkerd2/bin

echo "Uninjecting linkerd from namespace ingress-nginx"
kubectl get namespace ingress-nginx -o yaml | linkerd uninject - | kubectl replace -f -

echo "Uninjecting linkerd from namespace $NAMESPACE"
kubectl get namespace $NAMESPACE -o yaml | linkerd uninject - | kubectl replace -f -

echo "Restarting the ingress contrtoller to remove it to the mesh"
kubectl rollout restart deployments -n ingress-nginx ingress-nginx-controller

echo "Restarting storefront, stockmanager and zipkin to remove them to the mesh"
kubectl rollout restart deployments storefront stockmanager zipkin

echo "Running main linkerd tidy up script"

SAVD_DIR=`pwd`
cd ../linkerd
bash ./linkerd-uninstall.sh $NAMESPACE autoconfirm

cd $HOME/helidon-kubernetes/service-mesh

echo "Removing the local files"
touch auth tls-ld.crt tls-ld.key
rm auth tls-*.crt tls-*.key

echo "Removing the modified ingress-rule file"
bash ./reset-ingress-ip.sh autoconfirm
