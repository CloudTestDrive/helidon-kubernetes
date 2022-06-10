#!/bin/bash -f
echo "Destroying monitoring namespace"
kubectl delete namespace monitoring  --ignore-not-found=true

echo "Removing Certificates"
cd $HOME/helidon-kubernetes/monitoring-kubernetes
rm tls-*.crt
rm tls-*.key