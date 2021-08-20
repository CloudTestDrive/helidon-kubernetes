#!/bin/bash
cd $HOME/helidon-kubernetes/base-kubernetes
bash ./create-namespace.sh $1
echo Creating tls store secret
bash $HOME/helidon-kubernetes/setup/create-store-cert.sh $2
bash $HOME/helidon-kubernetes/setup/set-ingress-config.sh $2 skip
echo Creating services
kubectl apply -f servicesClusterIP.yaml
echo Services are 
kubectl get services
echo Creating ingress rules
kubectl apply -f ingressConfig.yaml
echo Ingress rules are
kubectl get ingress
bash ./create-secrets.sh
bash ./create-configmaps.sh
cd ..
bash ./deploy.sh
