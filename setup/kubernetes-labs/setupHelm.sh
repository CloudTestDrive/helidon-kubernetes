#!/bin/bash -f
echo Creating helm repo entries

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/           
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx        
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts             
helm repo add elastic https://helm.elastic.co                           
helm repo add bitnami https://charts.bitnami.com/bitnami     

echo Updating helm repos
helm repo update