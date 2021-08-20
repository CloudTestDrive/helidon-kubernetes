#!/bin/bash

f [ $# -eq 0 ]
  then
    echo Delete ingress controller and dashboard ?.
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

settingsFile=$HOME/clusterSettings
infoFile=$HOME/clusterInfo
echo Removing dashboard user
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl apply -f dashboard-user.yaml

echo Delete dashboard
helm uninstall kubernetes-dashboard --namespace kube-system 

echo Delete ingress-controller
helm uninstall ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx 

echo Delete ingress namespace
kubectl delete namespace ingress-nginx

echo resetting info and settings files
echo Not set > $settingsFile
echo Not set > $InfoFile