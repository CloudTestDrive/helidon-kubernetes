#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings"
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

VERRAZZANO_INSTALLED_VAR="VERRAZZANO_INSTALLED_IN_CLUSTER_""$CLUSTER_CONTEXT_NAME""=true"
if [ -z "${!VERRAZZANO_INSTALLED_VAR}"]
then
  echo "No record of installing verrazzano in cluster $CLUSTER_CONTEXT_NAME skipping"
  exit 0
else
  echo "Verrazzano is installed in cluster $CLUSTER_CONTEXT_NAME removing"
fi
echo "Unnstalling verrazzano, this will take a while"

# Get the name of the Verrazzano custom resource
MYVZ=$(kubectl  get vz -o jsonpath="{.items[0].metadata.name}")

# Delete the Verrazzano custom resource
kubectl delete verrazzano $MYVZ --wait=false
kubectl logs -n verrazzano-install \
    -f $(kubectl get pod \
    -n verrazzano-install \
    -l job-name=verrazzano-uninstall-${MYVZ} \
    -o jsonpath="{.items[0].metadata.name}")

bash ../../common/delete-from-saved-settings.sh "$VERRAZZANO_INSTALLED_VAR"