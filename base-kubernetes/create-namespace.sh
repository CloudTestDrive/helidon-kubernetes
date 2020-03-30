#!/bin/bash -f
echo Deleting old $1 namespace
kubectl delete namespace $1 --ignore-not-found=true
echo Creating new $1 namespace
kubectl create namespace $1
echo Setting default kubectl namespace
kubectl config set-context --current --namespace=$1