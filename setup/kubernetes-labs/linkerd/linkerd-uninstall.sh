#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo you must supply your namespace
    exit 1
fi
if [ $# -eq 1 ]
  then
    echo About to try to remove linkerd from namespace $NAMESPACE the ingress namespace and the cluster
    
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo Skipping confirmation of linkerd removal,  About to try to remove linkerd from namespace $NAMESPACE the ingress namespace and the cluster
fi

echo Checking for linkerd executable
echo linkerdLoc=`which linkerd | grep "no linkerd in"`
if [ -z $linkerdLoc ] 
  then
     echo Located linked command, continuing
  else
     echo Cannot locate linkerd command, so cant uninstall linkerd - or it may not have been installed to start with
     exit 2
fi

echo Checking for linkerd-viz namespace
linkerdViz=`kubectl get namespace linkerd-viz | grep  NotFound | wc -l` 
if [ $linkerdViz -eq 1 ] 
  then
     echo linkerd-viz namespace not found
  else
    echo found linkerd-viz namespace, uninstalling
    linkerd viz install | kubectl delete -f -
    kubectl delete namespace linkerd-viz --ignore-not-found=true
    echo linkerd-viz removed
fi

echo Checking for linkerd namespace
linkerd=`kubectl get namespace linkerd | grep  NotFound | wc -l` 
if [ $linkerdViz -eq 1 ]
  then
     echo linkerd namespace not found, finished linkerd removal script
     exit 0 
  else
    echo found linkerd-viz namespace, uninstalling
    echo removing annotations from namespace $NAMESPACE
    kubectl get namespace $NAMESPACE -o yaml | linkerd uninject - | kubectl replace -f -
    echo restarting services in $NAMESPACE
    kubectl rollout restart deployments storefront stockmanager zipkin

    echo removing annotations from namespace ingress-nginx
    kubectl get namespace ingress-nginx -o yaml | linkerd uninject - | kubectl replace -f -
    echo restarting services in ingress-nginx
    kubectl rollout restart deployments -n ingress-nginx ingress-nginx-controller
    
    linkerd install | kubectl delete -f -
    kubectl delete namespace linkerd --ignore-not-found=true
    echo linkerd removed
fi
