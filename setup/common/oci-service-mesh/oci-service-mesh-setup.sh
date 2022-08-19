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

if [ -z "$USER_INITIALS" ]
then
  echo "$SCRIPT_NAME Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 11
fi
if [ -z $VAULT_OCID ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo Found vault
fi

VAULT_KEY_NAME_BASE=RSA
SAVED_DIR=`pwd`
cd ../vault
VAULT_KEY_NAME=`bash ./vault-key-get-key-name.sh $VAULT_KEY_NAME_BASE`
VAULT_KEY_OCID_NAME=`bash ./vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`
VAULT_KEY_OCID="${!VAULT_KEY_OCID}"
cd $SAVED_DIR


if [ -z $VAULT_KEY_OCID ]
then
  echo "No vault key OCID for key base $VAULT_KEY_NAME_BASE (var named $VAULT_KEY_OCID_NAME in settings) , have you run the vault-setup.sh and / or vault-key-setup.sh for RSA scripts ?"
  echo "Cannot continue"
  exit 13
else
  echo "Found vault key"
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