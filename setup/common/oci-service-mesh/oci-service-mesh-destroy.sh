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

SERVICE_MESH_METRICS_SERVER_REUSED_NAME=`bash ./service-mesh-metrics-server-get-var-name-reused.sh $CLUSTER_CONTEXT_NAME`

# Now locate the value of the variable who's name is in SERVICE_MESH_METRICS_SERVER_REUSED_NAME and save it
SERVICE_MESH_METRICS_SERVER_REUSED="${!SERVICE_MESH_METRICS_SERVER_REUSED_NAME}"
if [ -z $SERVICE_MESH_METRICS_SERVER_REUSED ]
then
  echo "No reuse information for metrics server Oracle Service Operator for Kubernetes with context $CLUSTER_CONTEXT_NAME, ignoring"
else
  if [ "$SERVICE_MESH_METRICS_SERVER_REUSED" = true ]
  then
    echo "Metrics server was reused for Oracle Service Operator for Kubernetes with context $CLUSTER_CONTEXT_NAME, not removing"
  else
    echo "Metrics server was installed for Oracle Service Operator for Kubernetes with context $CLUSTER_CONTEXT_NAME, removing it"
    helm uninstall metrics-server --namespace kube-system  --kube-context $CLUSTER_CONTEXT_NAME
  fi
fi
bash ../delete-from-saved-settings.sh  "$SERVICE_MESH_METRICS_SERVER_REUSED_NAME"
