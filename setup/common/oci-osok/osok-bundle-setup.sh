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


if [ -z $USER_OCID ]
then
  echo "$SCRIPT_NAME  Your user OCID has not been set, you need to run the user-identity-setup.sh script before you can run this script"
  exit 1
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
  echo "No reuse information for Oracle Service Operator for Kubernetes with context $CLUSTER_CONTEXT_NAME"
else
  echo "This script has already configured the Oracle Service Operator for Kubernetes with  context $CLUSTER_CONTEXT_NAME, exiting"
  exit 0
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi


if [ -z $AUTH_TOKEN ]
then
  echo "There is no saved auth token which is needed to log in to docker"
  read -p "Please enter a valid auth token for your account" AUTH_TOKEN
  if [ -z $AUTH_TOKEN ]
  then
    echo "You did not enter an auth token, this script cannot proceed without that"
    echo "Script stopping"
    exit 4
  fi
else
  echo "Using the saved auth token for the docker login"
fi

SAVED_DIR=`pwd`
cd ../docker
bash docker-login.sh $OPERATOR_BUNDLE_OCIR_REGION
cd $SAVED_DIR

echo "Temporary fix copying kubeconfig"
KCONF=$HOME/.kube/config
TMP_KCONF="$KCONF"."$CLUSTER_CONTEXT_NAME".tmp
cp $KCONF $TMP_KCONF
echo "Setting temporaty config default context"
export KUBECONFIG=$TMP_KCONF
kubectl config use-context $CLUSTER_CONTEXT_NAME


echo "Creating OSOK namespace"
kubectl create ns oci-service-operator-system --context $CLUSTER_CONTEXT_NAME
echo "Installing OSOK"
$OPERATOR_SDK_PATH run bundle iad.ocir.io/oracle/oci-service-operator-bundle:$OSOK_BUNDLE_VERSION -n oci-service-operator-system --kubeconfig $KUBECONFIG --timeout 5m
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "$OPERATOR_SDK_CMD returned a non zero response, cannot continue"
  exit $RESP
fi


rm $TMP_KCONF
unset KUBECONFIG

echo "$OSOK_REUSED_NAME=false" >> $SETTINGS
