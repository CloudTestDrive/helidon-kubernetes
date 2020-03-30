#!/bin/bash
echo Setting up certificates
kubectl delete secret tls-secret  --ignore-not-found=true
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/CN=nginxsvc/O=nginxsvc"
kubectl create secret tls tls-secret --key tls.key --cert tls.crt
echo Creating ingress
kubectl apply -f ingressConfig.yaml
echo Services are 
kubectl get ingress
