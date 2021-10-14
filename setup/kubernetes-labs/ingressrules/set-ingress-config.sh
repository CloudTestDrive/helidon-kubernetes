#!/bin/bash
if [ $# -lt 2 ]
  then
    echo "Missing arguments supplied, you must provide the directory to process and External IP address of the ingress controler service"
    exit -1 
fi
if [ $# -eq 2 ]
  then
    echo Updating the ingress rules yaml in $1 to set $2 as the External IP address.
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
ingressdir=$1
newip=$2
echo Updating ingress rules - updating the ingress rules yaml in $ingressdir setting $newip as the external IP address
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/update-ingress.sh  $ingressdir '${EXTERNAL_IP}' $newip