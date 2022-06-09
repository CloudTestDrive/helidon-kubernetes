#!/bin/bash -f
echo "Destroying monitoring namespace"
kubectl delete namespace monitoring  --ignore-not-found=true