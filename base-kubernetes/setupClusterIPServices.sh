#!/bin/bash
echo Creating services
kubectl apply -f servicesClusterIP.yaml
echo Services are 
kubectl get services
