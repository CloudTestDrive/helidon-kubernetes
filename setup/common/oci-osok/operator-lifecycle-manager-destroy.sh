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
OLM_REUSED_NAME=`bash ../settings/to-valid-name.sh  "OPERATOR_LIFECYCLE_MANAGER_"$CLUSTER_CONTEXT_NAME"_REUSED"`
# Now locate the value of the variable who's name is in K3S_REUSED_NAME and save it
OLM_REUSED="${!OLM_REUSED_NAME}"
if [ -z $OLM_REUSED ]
then
  echo "No reuse information for operator lifecycle manager with context $CLUSTER_CONTEXT_NAME cannot remove it"
  exit 0
else
  echo "This script has configured the operator lifecycle manager with  context $CLUSTER_CONTEXT_NAME, removing it"
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "Unnstalling the operator lifecycle manager"

echo "Temporary fix copying kubeconfig"
KCONF=$HOME/.kube/config
TMP_KCONF="$KCONF"."$CLUSTER_CONTEXT_NAME".tmp
cp $KCONF $TMP_KCONF
echo "Setting temporaty config default context"
export KUBECONFIG=$TMP_KCONF
kubectl config use-context $CLUSTER_CONTEXT_NAME

echo "Uninstalling operator lifecycle manager in context $CLUSTER_CONTEXT_NAME"
$OPERATOR_SDK_PATH olm uninstall 
 
rm $TMP_KCONF
unset KUBECONFIG

bash ../delete-from-saved-settings.sh "$OLM_REUSED_NAME"