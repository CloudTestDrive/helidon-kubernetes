#!/bin/bash -f
source $HOME/clusterSettings
if [ $# -eq 0 ]
  then
    echo About to remove existing stack in $NAMESPACE and reset ingress config
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping confirmation"
fi
echo deleting existing deplpoyments in $NAMESPACE
kubectl delete namespace $NAMESPACE  --ignore-not-found=true
echo Blanking saved namespace
echo NAMESPACE= >> $HOME/clusterSettings
echo resetting ingress rules file
bash $HOME/helidon-kubernetes/base-kubernetes/scripts/reset-ingress-config.sh  $ip skip
