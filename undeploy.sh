#!/bin/bash
echo Deleting storefront deployment
kubectl delete -f storefront-deployment.yaml
echo Deleting stockmanager deployment
kubectl delete -f stockmanager-deployment.yaml
echo Deleting zipkin deployment
kubectl delete -f zipkin-deployment.yaml
echo Kubenetes config is
kubectl get all
