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
  echo "Your user OCID has not been set, you need to run the user-identity-setup.sh script before you can run this script"
  exit 1
fi
if [ -z $VAULT_OCID ]
then
  echo "Your vault OCID has not been set, you need to run the vault-setup.sh script before you can run this script"
  exit 1
fi
if [ -z $VAULT_KEY_OCID ]
then
  echo "Your vault key OCID has not been set, you need to run the vault-setup.sh script before you can run this script"
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


OCI_USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`

OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`
MAX_LOGIN_ATTEMPTS=12
DOCKER_LOGIN_FAILED_SLEEP_TIME=10
echo "About to docker login for operator bundle repo to $OPERATOR_BUNDLE_OCIR_REGION and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token as the password"
echo "Please ignore warnings about insecure password storage"
echo "It can take a short while for a new auth token to be propogated to the OCIR service, so if the docker login fails do not be alarmed the script will retry after a short delay."
for i in  `seq 1 $MAX_LOGIN_ATTEMPTS` 
do
  echo -n $AUTH_TOKEN | docker login $OPERATOR_BUNDLE_OCIR_REGION --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password-stdin
  RESP=$?
  echo "Docker Login resp is $RESP"
  if [ $RESP = 0 ]
  then
    echo "docker login to $OPERATOR_BUNDLE_OCIR_REGION suceeded on attempt $i, continuing"
    break ;
  else
    echo "docker login to $OPERATOR_BUNDLE_OCIR_REGION failed on attempt $i, retrying after pause"
    sleep $DOCKER_LOGIN_FAILED_SLEEP_TIME
  fi
  if [ $i -eq $MAX_LOGIN_ATTEMPTS ]
  then
    echo "Unable to complete docker login after 12 attempts, cannot continue"
    exit 10
  fi
done

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

# install the metrics server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update

helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system  --kubecontext $CLUSTER_CONTEXT_NAME

rm $TMP_KCONF
unset KUBECONFIG

echo "$OSOK_REUSED_NAME=false" >> $SETTINGS
