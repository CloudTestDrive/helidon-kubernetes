#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the External IP address of the ingress controler service"
    exit -1 
fi
if [ $# -eq 1 ]
  then
    echo Updating the ingress config to set $1 as the External IP address.
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping ingress rule setup confirmation"
fi
externip=$1
echo Updating ingress rules - setting $externip as the external IP address
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/set-ingress-config.sh $HOME/helidon-kubernetes/base-kubernetes $externip skip