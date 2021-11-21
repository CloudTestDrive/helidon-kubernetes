#!/bin/bash
if [ $# -eq 0 ]
  then
    echo Updating the ingress config to remove templated files.
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping ingress rule reset confirmation"
fi
echo Updating service mesh ingress rules - removing templated files
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/reset-ingress-config.sh $HOME/helidon-kubernetes/service-mesh skip