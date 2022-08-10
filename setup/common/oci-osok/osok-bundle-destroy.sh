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

OPERATOR_SETTINGS_FILE=./operator-settings.sh

if [ -f $OPERATOR_SETTINGS_FILE ]
  then
    echo "Loading operator settings"
    source $OPERATOR_SETTINGS_FILE
  else 
    echo "No operator settings file( $OPERATOR_SETTINGS_FILE) cannot continue"
    exit 11
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OSOK_REUSED_NAME=`bash ../settings/to-valid-name.sh  "OSOK_"$CLUSTER_CONTEXT_NAME"_REUSED"`
# Now locate the value of the variable who's name is in OSOK_REUSED_NAME and save it
OSOK_REUSED="${!OSOK_REUSED_NAME}"
if [ -z $OSOK_REUSED ]
then
  echo "No reuse information for Oracle Service Operator for Kubernetes with context $CLUSTER_CONTEXT_NAME unsafe to continue, exiting"
  exit 0
else
  echo "This script has already configured the Oracle Service Operator for Kubernetes with  context $CLUSTER_CONTEXT_NAME, removing"
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "Temporary fix copying kubeconfig"
KCONF=$HOME/.kube/config
TMP_KCONF="$KCONF"."$CLUSTER_CONTEXT_NAME".tmp
cp $KCONF $TMP_KCONF
echo "Setting temporaty config default context"
export KUBECONFIG=$TMP_KCONF
kubectl config use-context $CLUSTER_CONTEXT_NAME

echo "Installing OSOK"
$OPERATOR_SDK_PATH cleanup oci-service-operator -n oci-service-operator-system --kubeconfig $KUBECONFIG --timeout 5m
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "$OPERATOR_SDK_CMD returned a non zero response, cannot continue"
  exit $RESP
fi

echo "Deleting OSOK namespace"
kubectl delete ns oci-service-operator-system --context $CLUSTER_CONTEXT_NAME

rm $TMP_KCONF
unset KUBECONFIG


bash ../delete-from-saved-settings.sh  "$OSOK_REUSED_NAME"
