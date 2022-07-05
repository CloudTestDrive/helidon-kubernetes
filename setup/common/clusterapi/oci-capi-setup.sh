#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings
CAPI_SETTINGS_FILE=./capi-settings.sh

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi
if [ -z "$CAPI_PROVISIONER_REUSED" ]
then
  echo "no capi provisioner reuse information, proceeding"
else
  echo "capi provisioner already setup, exiting"
  exit 0
fi

if [ -f $CAPI_SETTINGS_FILE ]
  then
    echo "Loading capi settings"
    source $CAPI_SETTINGS_FILE
  else 
    echo "No capi settings file ( $CAPI_SETTINGS_FILE ) cannot continue"
    exit 11
fi

if [ -x "$CLUSTERCTL_PATH" ]
then
  echo "Located clusterctl command"
else
  echo "clusterctl command should be $CLUSTERCTL_PATH but it's not found or not executable, have you run the downloaded-clusterctl.sh script ?"
  exit 2
fi

# if the CAPI_DIR already exists then record as being reused
if [ -d "$CAPI_DIR" ]
then
  CAPI_PROVISIONER_REUSED=true
else
  CAPI_PROVISIONER_REUSED=false
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

# create the cluster api directory
mkdir -p $CAPI_DIR
#cat <<EOF > $HOME/.cluster-api/clusterctl.yaml
#providers:
#  - name: oci
#    url: https://github.com/oracle/cluster-api-provider-oci/releases/v$ORACLE_CAPI_VERSION/infrastructure-components.yaml
#    type: InfrastructureProvider
#EOF
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to install the cluster api provider into kubernetes cluster $CLUSTER_CONTEXT_NAME defaulting to $REPLY"
else
  read -p "Do you want to install the cluster api provider into kubernetes cluster $CLUSTER_CONTEXT_NAME (y/n) " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not installing"
  exit 1
fi
ORIG_K8S_CONTEXT=`kubectl config current-context`
# switch to our specified context
kubectl config use-context $CLUSTER_CONTEXT_NAME
if [ $? = 0 ]
then
  echo "Switch so context $CLUSTER_CONTEXT_NAME"
else
  echo "Unable to find kubernetes context $CURRENT_CONTEXT_NAME, cannot continue"
  exit 1
fi

echo "Setting up namespace for capi"
kubectl get namespace $CAPI_NAMESPACE > /dev/null
if [ $? = 0 ]
then
  echo "Cluster namespace $CAPI_NAMESPACE already exists, will reuse it"
  CAPI_NAMESPACE_REUSED=true
else
  echo "Creating cluster api namespace of $CAPI_NAMESPACE"
  kubectl create namespace $CAPI_NAMESPACE
  CAPI_NAMESPACE_REUSED=false
fi

echo "CAPI_NAMESPACE_REUSED=$CAPI_NAMESPACE_REUSED" >> $SETTINGS

echo "Installing cluster API provisioner into cluster $CLUSTER_CONTEXT_NAME"

$CLUSTERCTL_PATH init --infrastructure oci --target-namespace $CAPI_NAMESPACE

# revert to the origional context
kubectl config use-context $ORIG_K8S_CONTEXT

echo "Reverted to context $ORIG_K8S_CONTEXT"

echo "CAPI_PROVISIONER_REUSED"=$CAPI_PROVISIONER_REUSED >> $SETTINGS