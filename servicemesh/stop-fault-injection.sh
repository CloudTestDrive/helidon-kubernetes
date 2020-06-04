#!/bin/bash -f
kubectl delete -f fault-injector-traffic-split.yaml
kubectl delete -f fault-injector-ingress.yaml
kubectl delete -f fault-injector-service.yaml
kubectl delete -f nginx-fault-injector-deployment.yaml
kubectl delete -f nginx-fault-injector-configmap.yaml