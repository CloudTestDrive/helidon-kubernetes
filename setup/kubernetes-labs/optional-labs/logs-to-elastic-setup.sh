#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z "$SMALLSTEP_DIR"]
then 
    echo "Small step setup was not done my these scripts, cannot locate the step command, exiting"
    exit 0
else
    echo "Smallstep command located, continuing"
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

echo "Creating logging namespace in cluster $CLUSTER_CONTEXT_NAME"

kubectl create namespace logging --context $CLUSTER_CONTEXT_NAME

echo "Creating Elastic auth details in cluster $CLUSTER_CONTEXT_NAME"
htpasswd -c -b auth admin $PASSWORD

echo "Creating Elastic auth secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret generic web-ingress-auth -n logging --from-file=auth --context $CLUSTER_CONTEXT_NAME

echo "Creating Elastic search certificate in cluster $CLUSTER_CONTEXT_NAME"
$SMALLSTEP_DIR/step certificate create search.logging.$EXTERNAL_LP.nip.io tls-search-$EXTERNAL_IP.crt tls-search-$EXTERNAL_IP.key  --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $SMALLSTEP_DIR/root.crt --ca-key $SMALLSTEP_DIR/root.key

echo "Create search certificate secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret tls tls-search --key tls-search-$EXTERNAL_IP.key --cert tls-search-$EXTERNAL_IP.crt -n logging --context $CLUSTER_CONTEXT_NAME

echo "Installing elastic search with helm in cluster $CLUSTER_CONTEXT_NAME"
helm install elasticsearch elastic/elasticsearch --namespace logging --version $elasticSearchHelmChartVersion --set ingress.enabled=true --set ingress.tls[0].hosts[0]="search.logging.$EXTERNAL_IP.nip.io" --set ingress.tls[0].secretName=tls-search --set ingress.hosts[0].host="search.logging.$EXTERNAL_IP.nip.io" --set ingress.hosts[0].paths[0].path='/' --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-type"=basic --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-secret"=web-ingress-auth --set ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-realm"="Authentication Required"  --kube-context $CLUSTER_CONTEXT_NAME 
#--set ingress.annotations."kubernetes\.io/ingress\.class"=nginx

echo "Installing fluentd daemon set in cluster $CLUSTER_CONTEXT_NAME"
kubectl apply -f fluentd-daemonset-elasticsearch-rbac.yaml --context $CLUSTER_CONTEXT_NAME

TODAYS_DATE=`date +'%Y.%m.%d'`
echo "Access elastic records for today at :"
echo "https://search.logging."$EXTERNAL_IP".nip.io/logstash-"$TODAYS_DATE"/_search"
echo "Access elastic records for storefront today at :"
echo "at https://search.logging."$EXTERNAL_IP".nip.io/logstash-"$TODAYS_DATE"/_search?q=kubernetes.container_name:storefront"
echo "auth user admin and password $PASSWORD"
echo "\nIt can take a while for the elastic stack to fully install and be running"
