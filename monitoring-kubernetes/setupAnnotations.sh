#!/bin/bash
STOREFRONTPOD=`kubectl get pods -l "app=storefront" -o jsonpath="{.items[0].metadata.name}"`
echo Storefront pod is $STOREFRONTPOD
kubectl annotate pod $STOREFRONTPOD prometheus.io/scrape=true --overwrite
kubectl annotate pod $STOREFRONTPOD prometheus.io/path=/metrics --overwrite
kubectl annotate pod $STOREFRONTPOD prometheus.io/port=9080 --overwrite
echo Storefront annotations are 
kubectl get pod $STOREFRONTPOD -o jsonpath="{.metadata..annotations}"
STOCKMANAGERPOD=`kubectl get pods -l "app=stockmanager" -o jsonpath="{.items[0].metadata.name}"`
echo Stockmanager pod is $STOCKMANAGERPOD
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/scrape=true --overwrite
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/path=/metrics --overwrite
kubectl annotate pod $STOCKMANAGERPOD prometheus.io/port=9081 --overwrite
echo Stockmanager annotations are 
kubectl get pod $STOCKMANAGERPOD -o jsonpath="{.metadata..annotations}"
