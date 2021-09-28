#!/bin/bash
echo Deleting existing services
echo Storefront
kubectl delete service storefront --ignore-not-found=true
echo Stockmanager
kubectl delete service stockmanager --ignore-not-found=true
echo Zipkin
kubectl delete service zipkin --ignore-not-found=true
echo Deleted services
echo Services remaining in namespace are 
kubectl get services
echo Creating services
echo Zipkin
kubectl apply -f serviceZipkin.yaml
echo Stockmanager
kubectl apply -f serviceStockmanager.yaml
echo Storefront
kubectl apply -f serviceStorefront.yaml
echo Current services in namespace are 
kubectl get services

