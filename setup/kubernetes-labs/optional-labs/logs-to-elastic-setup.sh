#!/bin/bash -f



CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
source ../helmChartVersions.sh


cd $HOME/helidon-kubernetes/management/logging

PASSWORD=ZaphodBeeblebrox

helm repo add elastic https://helm.elastic.co
helm repo update

echo "Creating logging namespace"

kubectl create namespace logging

echo "Creating Elastic auth details"
htpasswd -c -b auth admin $PASSWORD

echo "Creating Elastic auth secret"
kubectl create secret generic web-ingress-auth -n logging --from-file=auth

echo "Creating Elastic search certificate"
$HOME/keys/step certificate create search.logging.$EXTERNAL_LP.nip.io tls-search-$EXTERNAL_IP.crt tls-search-$EXTERNAL_IP.key  --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Create search certificate secret"
kubectl create secret tls tls-search --key tls-search-$EXTERNAL_IP.key --cert tls-search-$EXTERNAL_IP.crt -n logging

echo "Installing elastic search with helm"
helm install elasticsearch elastic/elasticsearch --namespace logging --version $elasticSearchHelmChartVersion --set ingress.enabled=true --set ingress.tls[0].hosts[0]="search.logging.$EXTERNAL_IP.nip.io" --set ingress.tls[0].secretName=tls-search --set ingress.hosts[0].host="search.logging.$EXTERNAL_IP.nip.io" --set ingress.hosts[0].paths[0].path='/' --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-type"=basic --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-secret"=web-ingress-auth --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-realm"="Authentication Required" 
#--set ingress.annotations."kubernetes\.io/ingress\.class"=nginx

echo "Installing fluentd daemon set"
kubectl apply -f fluentd-daemonset-elasticsearch-rbac.yaml

TODAYS_DATE=`date +'%Y.%m.%d'`
echo "Access elastic records for today at :"
echo "https://search.logging."$EXTERNAL_IP".nip.io/logstash-"$TODAYS_DATE"/_search"
echo "Access elastic records for storefront today at :"
echo "at https://search.logging."$EXTERNAL_IP".nip.io/logstash-"$TODAYS_DATE"/_search?q=kubernetes.container_name:storefront"
echo "auth user admin and password $PASSWORD"
echo "\nIt can take a while for the elastic stack to fully install and be running"
