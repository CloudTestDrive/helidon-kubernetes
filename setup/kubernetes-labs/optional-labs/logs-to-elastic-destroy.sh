#!/bin/bash -f


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