#!/bin/bash
if [ $# -lt 2 ]
  then
    echo "Missing arguments supplied, you must provide the directory to process and External IP address of the ingress controler service"
    exit -1 
fi
ingressdir=$1
newip=$2
if [ $# -eq 2 ]
  then
    echo Templating the ingress rules yaml in $ingressdir to set $newip as the External IP address.
    read -p "Proceed ? " 
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping ingress rule setup confirmation"
fi
echo Templating ingress rules - updating the template ingress rules yaml in $ingressdir setting $newip as the external IP address
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/template-ingress.sh  $ingressdir '${EXTERNAL_IP}' $newip