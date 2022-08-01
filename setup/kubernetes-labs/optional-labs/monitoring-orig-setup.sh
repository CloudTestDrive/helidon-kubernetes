#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

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
source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
source ../helmChartVersions.sh
PROMETHEUS_PASSWORD=ZaphodBeeblebrox

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update


cd $HOME/helidon-kubernetes/monitoring-kubernetes

echo "Creating namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl create namespace monitoring --context $CLUSTER_CONTEXT_NAME

echo "Creating Prometheus auth details"
htpasswd -c -b auth.$CLUSTER_CONTEXT_NAME admin $PROMETHEUS_PASSWORD

echo "Creating Prometheus auth secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret generic web-ingress-auth -n monitoring --from-file=auth.$CLUSTER_CONTEXT_NAME --context $CLUSTER_CONTEXT_NAME

echo "Create Prometheus certificate"
$HOME/keys/step certificate create prometheus.monitoring.$EXTERNAL_IP.nip.io tls-prometheus-$EXTERNAL_IP.crt tls-prometheus-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Create Prometheus certificate secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret tls tls-prometheus --key tls-prometheus-$EXTERNAL_IP.key --cert tls-prometheus-$EXTERNAL_IP.crt -n monitoring --context $CLUSTER_CONTEXT_NAME

echo "Installing Prometheus using helm in cluster $CLUSTER_CONTEXT_NAME"
helm install prometheus prometheus-community/prometheus --namespace monitoring --version $prometheusHelmChartVersion --set server.ingress.enabled=true --set server.ingress.hosts="{prometheus.monitoring.$EXTERNAL_IP.nip.io}" --set server.ingress.tls[0].secretName=tls-prometheus --set server.ingress.annotations."kubernetes\.io/ingress\.class"=nginx --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-type"=basic --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-secret"=web-ingress-auth --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-realm"="Authentication Required" --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false  --kube-context $CLUSTER_CONTEXT_NAME

echo "Configuring and restarting the pods with Prometheus annotations"
bash ./configure-pods-for-prometheus.sh $CLUSTER_CONTEXT_NAME

echo "Creating Grafana certificate"
$HOME/keys/step certificate create grafana.monitoring.$EXTERNAL_IP.nip.io tls-grafana-$EXTERNAL_IP.crt tls-grafana-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Creating Grafana certificate secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret tls tls-grafana --key tls-grafana-$EXTERNAL_IP.key --cert tls-grafana-$EXTERNAL_IP.crt -n monitoring --context $CLUSTER_CONTEXT_NAME

echo "Installing Grafana using helm in cluster $CLUSTER_CONTEXT_NAME"
helm install grafana grafana/grafana --version $grafanaHelmChartVerion --namespace  monitoring  --set persistence.enabled=true --set ingress.enabled=true --set ingress.hosts="{grafana.monitoring.$EXTERNAL_IP.nip.io}" --set ingress.tls[0].secretName=tls-grafana --set ingress.annotations."kubernetes\.io/ingress\.class"=nginx  --kube-context $CLUSTER_CONTEXT_NAME --set datasources."datasource\.yaml\.apiVersion"=1 --set datasources."datasource\.yaml\.datasources[0].name"=Prometheus  --set datasources."datasource\.yaml\.datasources[0].type"=Prometheus  --set datasources."datasource\.yaml\.datasources[0].url"=http://prometheus-server.monitoring.svc.cluster.local --set datasources."datasource\.yaml\.datasources[0].isDefault"=true
echo "Retrieving Grafana login password from cluster $CLUSTER_CONTEXT_NAME"
GRAFANA_PASSWORD=`kubectl get secret  --context $CLUSTER_CONTEXT_NAME --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

echo "Access prometheus for cluster $CLUSTER_CONTEXT_NAME at https://prometheus.monitoring.$EXTERNAL_IP.nip.io with username admin and password $PROMETHEUS_PASSWORD"
echo "Remember to enable the monitoring annotations in the pods"

echo "Access Grafana for cluster $CLUSTER_CONTEXT_NAME at https://grafana.monitoring.$EXTERNAL_IP.nip.io using user admin and password"
echo $GRAFANA_PASSWORD

echo "Remember to set the data source as prometheus on http://prometheus-server.monitoring.svc.cluster.local"