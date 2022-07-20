#!/bin/bash -f
currentContext=`bash get-current-context.sh`
settingsFile=$HOME/clusterSettings.$currentContext
source $settingsFile

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Autpo confirm enabled, About to remove existing stack in $NAMESPACE and reset ingress config and update cluster settings file $settingsFile Kuberetes context is $currentContext defaults to $REPLY"
else
  echo "About to remove existing stack in $NAMESPACE and reset ingress config and update cluster settings file $settingsFile Kuberetes context is $currentContext"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "About to remove existing stack in $NAMESPACE cluster settings file $settingsFile Kuberetes context is $currentContext"
fi
echo "Attempting to run linker removal script"
bash linkerd/linkerd-uninstall.sh $NAMESPACE skip
echo "deleting monitoring namespace - if present"
kubectl delete namespace monitoring --ignore-not-found=true
echo "deleting logging namespace - if present"
kubectl delete namespace logging --ignore-not-found=true
echo "deleting your existing deployments in $NAMESPACE"
kubectl delete namespace $NAMESPACE  --ignore-not-found=true
echo "reseting to default namespace"
kubectl config set-context --current --namespace=default
echo "Blanking saved namespace"
echo NAMESPACE= >> $settingsFile
echo "Tidying up security certificates and keys specific to $EXTERNAL_IP"
bash delete-certs.sh $EXTERNAL_IP skip
