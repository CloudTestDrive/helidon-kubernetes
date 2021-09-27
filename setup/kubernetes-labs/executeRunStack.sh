#!/bin/bash
cd $HOME/helidon-kubernetes/base-kubernetes
echo Setup namespace
bash ./create-namespace.sh $1
echo NAMESPACE=$1 >> $HOME/clusterSettings
echo Creating tls store secret
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/create-store-cert.sh $2
bash ./set-ingress-ip.sh $2 skip
bash ./create-services.sh
bash ./create-ingress-rules.sh
bash ./create-secrets.sh
bash ./create-configmaps.sh
cd ..
bash ./deploy.sh

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/waitForServices.sh $1