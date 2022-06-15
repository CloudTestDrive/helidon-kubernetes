#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi


echo "Destroying logging namespace"
kubectl delete namespace logging  --ignore-not-found=true

echo "Removing Certificates"
cd $HOME/helidon-kubernetes/management/logging
# make sure there is something to delete
touch tls-deleteme.crt
touch tls-deleteme.key
# delete them
rm tls-*.crt
rm tls-*.key

echo "Removing auth file"
rm auth
