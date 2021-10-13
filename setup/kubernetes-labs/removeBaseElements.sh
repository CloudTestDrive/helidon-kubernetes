#!/bin/bash


if [ $# -eq 0 ]
  then
    echo Delete ingress controller and dashboard ?
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping remove base elements confirmation"
fi

currentContext=`bash get-current-context.sh`
settingsFile=$HOME/clusterSettings.$currentContext
infoFile=$HOME/clusterInfo.$currentContext

source $settingsFile
echo Removing dashboard user
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl delete -f dashboard-user.yaml

echo Remove metrics server
helm uninstall metrics-server --namespace kube-system

echo Delete dashboard
helm uninstall kubernetes-dashboard --namespace kube-system 

echo Delete ingress-controller
helm uninstall ingress-nginx  --namespace ingress-nginx 

echo Delete ingress namespace
kubectl delete namespace ingress-nginx

echo resetting ingress rules files
# Just to be sure
echo resetting base ingress rules
bash $HOME/helidon-kubernetes/base-kubernetes/reset-ingress-ip.sh $ip skip
echo resetting service mesh ingress rules
bash $HOME/helidon-kubernetes/service-mesh/reset-ingress-ip.sh $ip skip

echo resetting info and settings files
echo Not set > $settingsFile
echo Not set > $infoFile