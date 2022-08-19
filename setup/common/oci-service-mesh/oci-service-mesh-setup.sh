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

if [ -z $VAULT_OCID ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo Found vault
fi

if [ -z $VAULT_KEY_OCID ]
then
  echo "No vault key OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 13
else
  echo Found vault key
fi

echo "Checking for metrics server"
METRICS_SERVER_COUNT=`helm list --namespace kube-system --kube-context $CLUSTER_CONTEXT_NAME | grep '^metrics-server' | wc -l`
if [ "$METRICS_SERVER_COUNT" -eq 0 ]
then
  echo "Metrics server not installed, setting up repo and installing"
  # install the metrics server
  helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
  helm repo update

  helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system  --kube-context $CLUSTER_CONTEXT_NAME
  METRICS_SERVER_REUSED=true
else
  echo "Metrics server already installed, skipping instalation"
  METRICS_SERVER_REUSED=false
fi

SERVICE_MESH_METRICS_SERVER_REUSED_NAME=`bash ./service-mesh-metrics-server-get-var-name-reused.sh $CLUSTER_CONTEXT_NAME`

echo "$SERVICE_MESH_METRICS_SERVER_REUSED_NAME=$METRICS_SERVER_REUSED" >> $SETTINGS