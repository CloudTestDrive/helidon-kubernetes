#!/bin/bash -f
currentContext=`bash get-current-context.sh`
settingsFile=$HOME/clusterSettings.$currentContext
source $settingsFile
if [ $# -eq 1 ]
  then
    echo About to remove existing stack in $NAMESPACE and reset ingress config and update cluster settings file $settingsFile Kuberetes context is $currentContext
    
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping confirmation of stack teardown,  About to remove existing stack in $NAMESPACE cluster settings file $settingsFile Kuberetes context is $currentContext"
fi
echo deleting linkerd-viz namespace - if present
kubectl delete namespace linkerd-viz --ignore-not-found=true
echo deleting linkerd namespace - if present
kubectl delete namespace linkerd --ignore-not-found=true
echo deleting monitoring namespace - if present
kubectl delete namespace monitoring --ignore-not-found=true
echo deleting logging namespace - if present
kubectl delete namespace logging --ignore-not-found=true
echo deleting your existing deployments in $NAMESPACE
kubectl delete namespace $NAMESPACE  --ignore-not-found=true
echo reseting to default namespace
kubectl config set-context --current --namespace=default
echo Blanking saved namespace
echo NAMESPACE= >> $settingsFile
bash delete-certs.sh skip
