#!/bin/bash
echo Creating zipkin deployment
kubectl apply -f zipkin-deployment.yaml --record=true
echo Creating stockmanager deployment
kubectl apply -f stockmanager-deployment.yaml --record=true
echo Creating storefront deployment
kubectl apply -f storefront-deployment.yaml --record=true
echo Kubenetes config is
kubectl get all
