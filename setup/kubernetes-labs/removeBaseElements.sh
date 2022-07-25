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
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Delete ingress controller and dashboard  from cluster $CLUSTER_CONTEXT_NAME? defaults to $REPLY"
else
  echo "Delete ingress controller and dashboard  from cluster $CLUSTER_CONTEXT_NAME ?"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Removing the base elements (ingress controller, metrics server, and dashboard) from cluster $CLUSTER_CONTEXT_NAME"
fi

settingsFile=$HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
infoFile=$HOME/clusterInfo.$CLUSTER_CONTEXT_NAME

source $settingsFile
echo "Removing dashboard user"
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl delete -f dashboard-user.yaml --context $CLUSTER_CONTEXT_NAME

echo "Remove metrics server"
helm uninstall metrics-server --namespace kube-system --kube-context $CLUSTER_CONTEXT_NAME

echo "Delete dashboard"
helm uninstall kubernetes-dashboard --namespace kube-system  --kube-context $CLUSTER_CONTEXT_NAME

echo "Delete ingress-controller"
helm uninstall ingress-nginx  --namespace ingress-nginx  --kube-context $CLUSTER_CONTEXT_NAME

echo "Delete ingress namespace"
kubectl delete namespace ingress-nginx --context $CLUSTER_CONTEXT_NAME

echo "resetting ingress rules files"
# Just to be sure 
echo "resetting base ingress rules"
bash $HOME/helidon-kubernetes/base-kubernetes/reset-ingress-ip.sh $CLUSTER_CONTEXT_NAME
echo "resetting persistence ingress rules"
bash $HOME/helidon-kubernetes/persistence/reset-ingress-ip.sh $CLUSTER_CONTEXT_NAME
echo "resetting service mesh ingress rules"
bash $HOME/helidon-kubernetes/service-mesh/reset-ingress-ip.sh $CLUSTER_CONTEXT_NAME

echo "resetting info and settings files"
echo "Not set" > $settingsFile
echo "Not set" > $infoFile