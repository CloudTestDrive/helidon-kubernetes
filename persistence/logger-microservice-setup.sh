#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 1 ]
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
# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
K8S_LOGGING_APPLIED_NAME=`bash ../setup/common/settings/to-valid-name.sh  "K8S_LOGGING_APPLIED_"$CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in K8S_LOGGING_APPLIED_NAME and save it
K8S_LOGGING_APPLIED="${!K8S_LOGGING_APPLIED_NAME}"
if [ -z "$K8S_LOGGING_APPLIED" ]
then
  echo "No record of configuring the logging / persistence for Kubernetes context $CLUSTER_CONTEXT_NAME"
  echo "starting configuration"
else
  echo "This script has already configured the logging / persistence for Kubernetes context $CLUSTER_CONTEXT_NAME, exiting"
  exit 0
fi
# This assumes that the ingress rules and deployment have been updated
echo "Creating persistent volume for the logger"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f persistentVolumeClaim.yaml
echo "Creating logger secrets"
bash create-secrets.sh $CLUSTER_CONTEXT_NAME
echo "Creating logger configmaps"
bash create-configmaps.sh $CLUSTER_CONTEXT_NAME
echo "Creating logger service"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f serviceLogger.yaml
echo "Creating the deployment"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f logger-deployment.yaml
echo "Creating the ingress rule"
kubectl apply --context $CLUSTER_CONTEXT_NAME -f ingressLoggerRules-"$CLUSTER_CONTEXT_NAME".yaml
echo "Updating the storefront context and restarting"
bash update-storefront-configmap.sh set $CLUSTER_CONTEXT_NAME

echo "$K8S_LOGGING_APPLIED_NAME=true" >> $SETTINGS