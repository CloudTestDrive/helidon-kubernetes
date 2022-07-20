#!/bin/bash


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Delete ingress controller and dashboard ? defaults to $REPLY"
else
  echo "Delete ingress controller and dashboard ?"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Remoivign the base elements (ingrss controller, metrics server, and dashboard)"
fi

currentContext=`bash get-current-context.sh`
settingsFile=$HOME/clusterSettings.$currentContext
infoFile=$HOME/clusterInfo.$currentContext

source $settingsFile
echo "Removing dashboard user"
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl delete -f dashboard-user.yaml

echo "Remove metrics server"
helm uninstall metrics-server --namespace kube-system

echo "Delete dashboard"
helm uninstall kubernetes-dashboard --namespace kube-system 

echo "Delete ingress-controller"
helm uninstall ingress-nginx  --namespace ingress-nginx 

echo "Delete ingress namespace"
kubectl delete namespace ingress-nginx

echo "resetting ingress rules files"
# Just to be sure
echo "resetting base ingress rules"
bash $HOME/helidon-kubernetes/base-kubernetes/reset-ingress-ip.sh skip
echo "resetting service mesh ingress rules"
bash $HOME/helidon-kubernetes/service-mesh/reset-ingress-ip.sh skip

echo "resetting info and settings files"
echo "Not set" > $settingsFile
echo "Not set" > $infoFile