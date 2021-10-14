#!/bin/bash -f
kubectl delete -f stockmanager-deployment-v0.0.2.yaml
kubectl delete -f stockmanager-canary-traffic-split.yaml
kubectl delete -f ingressStockmanagerCanaryRules.yaml
kubectl delete -f stockmanager-v0.0.2-service.yaml 
kubectl delete -f stockmanager-v0.0.1-service.yaml 
