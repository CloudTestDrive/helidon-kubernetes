#!/bin/bash
DEVDIR=../..
FRONTDIR=$DEVDIR/helidon-labs-storefront
MGRDIR=$DEVDIR/helidon-labs-stockmanager
echo Deleting existing config maps
echo sf-config-map
kubectl delete configmap sf-config-map --ignore-not-found=true
echo sm-config-map
kubectl delete configmap sm-config-map --ignore-not-found=true
echo Config Maps remaining in namespace are 
kubectl get configmaps
echo Creating config maps
echo sf-config-map
kubectl create configmap sf-config-map --from-file=$FRONTDIR/conf
echo sm-config-map
kubectl create configmap sm-config-map --from-file=$MGRDIR/conf
echo Existing in namespace are 
kubectl get configmaps

