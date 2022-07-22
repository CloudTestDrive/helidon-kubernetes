#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
then
  echo "Missing argunment supplied to $SCRIPT_NAME"
  echo "  1st arg you must supply your namespace"
  echo "Optional"
  echi "  2nd arg cluster context - defaults to one"
  exit 1
fi
NAMESPACE=$1
CLUSTER_CONTEXT_NAME=one
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$4
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME  Using default context name of $CLUSTER_CONTEXT_NAME"
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm is enabled, About to try to remove linkerd from cluster $CLUSTER_CONTEXT_NAME - namespace $NAMESPACE the ingress namespace and the cluster defaults to $REPLY"
else
  echo "About to try to remove linkerd from cluster $CLUSTER_CONTEXT_NAME - namespace $NAMESPACE the ingress namespace and the cluster"
  read -p "Proceed (y/n) ?"  REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "OK  About to try to remove linkerd from cluster $CLUSTER_CONTEXT_NAME - namespace $NAMESPACE the ingress namespace"
fi

echo "Checking for linkerd executable"
which linkerd 
linkerdLoc=$?
if [ $linkerdLoc -eq 0 ] 
  then
     echo "Located linked command on the path, continuing"
  else
     echo "Cannot locate linkerd command on the path, so cant uninstall linkerd - or it may not have been installed to start with"
     exit 2
fi

echo "Checking for linkerd-viz namespace in cluster $CLUSTER_CONTEXT_NAME"
linkerdViz=`kubectl get namespace linkerd-viz --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME | grep  linkerd-viz | wc -l` 
if [ $linkerdViz -eq 0 ] 
then
  echo "linkerd-viz namespace not found in cluster $CLUSTER_CONTEXT_NAME"
else
  echo "found linkerd-viz namespace, uninstalling from cluster $CLUSTER_CONTEXT_NAME"
  linkerd viz install | kubectl delete --context $CLUSTER_CONTEXT_NAME -f -
  kubectl delete namespace linkerd-viz --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
  echo "linkerd-viz removed"
fi

echo "Checking for linkerd namespace in cluster $CLUSTER_CONTEXT_NAME"
linkerd=`kubectl get namespace linkerd  --context $CLUSTER_CONTEXT_NAME --ignore-not-found=true| grep  linkerd | wc -l` 
if [ $linkerdViz -eq 0 ]
then
   echo "linkerd namespace not found in cluster $CLUSTER_CONTEXT_NAME, finished linkerd removal script"
   exit 0 
else
  echo "found linkerd-viz namespace in cluster $CLUSTER_CONTEXT_NAME, uninstalling"
  echo "removing annotations from namespace $NAMESPACE in cluster $CLUSTER_CONTEXT_NAME"
  kubectl get namespace $NAMESPACE --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd uninject - | kubectl replace -f -
  echo "restarting services in $NAMESPACE  in cluster $CLUSTER_CONTEXT_NAME"
  kubectl rollout restart deployments storefront stockmanager zipkin --context $CLUSTER_CONTEXT_NAME
  echo "removing annotations from namespace ingress-nginx  in cluster $CLUSTER_CONTEXT_NAME"
  kubectl get namespace ingress-nginx --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd uninject - | kubectl replace -f -
  echo "restarting services in ingress-nginx  in cluster $CLUSTER_CONTEXT_NAME"
  kubectl rollout restart deployments -n ingress-nginx ingress-nginx-controller --context $CLUSTER_CONTEXT_NAME
    
  linkerd install | kubectl delete --context $CLUSTER_CONTEXT_NAME -f -
  kubectl delete namespace linkerd --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
  echo "linkerd uninstalled from cluster $CLUSTER_CONTEXT_NAME"
fi
