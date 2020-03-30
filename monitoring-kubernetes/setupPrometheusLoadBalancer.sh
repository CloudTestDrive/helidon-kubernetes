#!/bin/bash
echo Creating prometheus loadbalancer servcie
kubectl apply -f servicesLoadBalancer.yaml
echo Services are 
kubectl get services -n monitoring
