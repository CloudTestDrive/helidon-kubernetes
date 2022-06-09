#!/bin/bash -f


CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
source helmChartVersions.sh
PROMETHEUS_PASSWORD=ZaphodBeeblebrox

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update


cd $HOME/helidon-kubernetes/monitoring-kubernetes

echo "Creating namespace"
kubectl create namespace monitoring

echo "Creating Prometheus auth details"
htpasswd -c -b auth admin $PROMETHEUS_PASSWORD

echo "Creating Prometheus auth secret"
kubectl create secret generic web-ingress-auth -n monitoring --from-file=auth

echo "Create Prometheus certificate"
$HOME/keys/step certificate create prometheus.monitoring.$EXTERNAL_IP.nip.io tls-prometheus-$EXTERNAL_IP.crt tls-prometheus-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Create Prometheus certificate secret"
kubectl create secret tls tls-prometheus --key tls-prometheus-$EXTERNAL_IP.key --cert tls-prometheus-$EXTERNAL_IP.crt -n monitoring

echo "Installing Prometheus using helm"
helm install prometheus prometheus-community/prometheus --namespace monitoring --version $prometheusHelmChartVersion --set server.ingress.enabled=true --set server.ingress.hosts="{prometheus.monitoring.$EXTERNAL_IP.nip.io}" --set server.ingress.tls[0].secretName=tls-prometheus --set server.ingress.annotations."kubernetes\.io/ingress\.class"=nginx --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-type"=basic --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-secret"=web-ingress-auth --set server.ingress.annotations."nginx\.ingress\.kubernetes\.io/auth-realm"="Authentication Required" --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false --set pushgateway.persistentVolume.enabled=false

echo "Access prometheus at https://prometheus.monitoring.$EXTERNAL_IP.nip.io wiuth username admin and password $PROMETHEUS_PASSWORD"
echo "Remember to enable the monitoring"

echo "Creating Helm certificate"
$HOME/keys/step certificate create grafana.monitoring.$EXTERNAL_IP.nip.io tls-grafana-$EXTERNAL_IP.crt tls-grafana-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Creating Helm certificate secret"
kubectl create secret tls tls-grafana --key tls-grafana-$EXTERNAL_IP.key --cert tls-grafana-$EXTERNAL_IP.crt -n monitoring

echo "Installing Grafana using helm"
helm install grafana grafana/grafana --version $grafanaHelmChartVerion --namespace  monitoring  --set persistence.enabled=true --set ingress.enabled=true --set ingress.hosts="{grafana.monitoring.$EXTERNAL_IP.nip.io}" --set ingress.tls[0].secretName=tls-grafana

echo "Retrieving Grafana login password"
GRAFANA_PASSWORD=`kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

echo "Access Grafana at https://grafana.monitoring.$EXTERNAL_IP.nip.io using password"
echo $GRAFANA_PASSWORD

echo "Remember to set the data source as prometheus on http://prometheus-server.monitoring.svc.cluster.local"