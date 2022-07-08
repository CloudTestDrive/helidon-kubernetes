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

if [ -d $CAPI_DIR ]
then
  echo "Will use $CAPI_DIR as the working directory"
else
  echo "Can't locate the directory $CAPI_DIR have you run the oci-capi-setup.sh script ?"
  exit 4
fi

if [ -z "$CAPI_PROVISIONER_REUSED" ]
then
  echo "no capi provisioner reuse information, has the oci-capi-setup.sh script been run ? cannot continue."
  exit 1
else
  echo "capi provisioner setup, continuing"
fi

if [ -z "$USER_INITIALS" ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
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


CAPI_CONTEXT_NAME="$USER_INITIALS"-capi

if [ $# -gt 0 ]
then
  CAPI_CONTEXT_NAME=$1
  echo "Operating on capi context name $CAPI_CONTEXT_NAME"
else
  echo "Using default capi context name of $CAPI_CONTEXT_NAME"
fi

KUBE_CONTEXT=one
if [ $# -gt 1 ]
then
  KUBE_CONTEXT=$1
  echo "Operating on kubeconfig context name $KUBE_CONTEXT"
else
  echo "Using default kubeconfig context name of $KUBE_CONTEXT"
fi
# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
CAPI_CLUSTER_REUSED_NAME=`bash ../settings/to-valid-name.sh CAPI_REUSED_$CAPI_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OCAPI_REUSED_NAME and save it
CAPI_CLUSTER_REUSED="${!CAPI_CLUSTER_REUSED_NAME}"
if [ -z $CAPI_CLUSTER_REUSED ]
then
  echo "No reuse information for CAPI cluster $CAPI_CONTEXT_NAME, cannot proceed"
  exit 0
else
  echo "This script has configured a capi cluster for context $CAPI_CONTEXT_NAME, continuing"
fi

CAPI_YAML=$CAPI_DIR/capi-cluster-$CAPI_CONTEXT_NAME.yaml

if [ -f "$CAPI_YAML" ]
then
  echo "Located cluster api definition in $CAPI_YAML"
else
  echo "Cannot locate cluster api yaml file $CAPI_YAML which created the cluster, cannot delete it"
  exit 0
fi

CAPI_CLUSTER_NAMESPACE_REUSED_NAME==`bash ../settings/to-valid-name.sh "CAPI_CLUSTER_NAMESPACE_"$CAPI_CLUSTER_NAMESPACE"_REUSED"`
CAPI_CLUSTER_NAMESPACE_REUSED="${!CAPI_CLUSTER_NAMESPACE_REUSED_NAME}"
if [ -z "$CAPI_CLUSTER_NAMESPACE_REUSED" ]
then
  echo "No reuse information for CAPI cluster namespace $CAPI_CLUSTER_NAMESPACE, cannot proceed"
  exit 0
else
  echo "This script has reuse info for capi cluster namespace $CAPI_CLUSTER_NAMESPACE, continuing"
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to destroy the cluster API cluster and associated management resources named $CAPI_CONTEXT_NAME defaulting to $REPLY"
else
  read -p "Do you want to destroy the cluster API cluster and associated management resources named $CAPI_CONTEXT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK stopping capi cluster deletion"
  exit 1
fi

# delete the ssh key
SAVED_DIR=`pwd`
cd ../ssh-keys
bash ./ssh-key-destroy.sh $HOME/ssh id_rsa_capi_$CAPI_CONTEXT_NAME
cd $SAVED_DIR

# is there already a context with that name ?
CAPI_CONTEXT_NAME_EXISTS=`kubectl config get-contexts -o name | grep -w $CAPI_CONTEXT_NAME`

if [ -z $CAPI_CONTEXT_NAME_EXISTS ]
then
  echo "No kube contaxt name $CAPI_CONTEXT_NAME exists, skipping context removal"
else
  echo "Removing context $CAPI_CONTEXT_NAME from the local kubernetes configuration"
  CAPI_CLUSTER_INFO=`kubectl config get-contexts $CAPI_CONTEXT_NAME | grep -v NAMESPACE | sed -e 's/*//' | awk '{print $2}'`
  CAPI_USER_INFO=`kubectl config get-contexts $CAPI_CONTEXT_NAME | grep -v NAMESPACE | sed -e 's/*//' | awk '{print $3}'`
  kubectl config delete-user $CAPI_USER_INFO
  kubectl config delete-cluster $CAPI_CLUSTER_INFO
  kubectl config delete-context $CAPI_CONTEXT_NAME
  echo "The kubernetes context $CAPI_CONTEXT_NAME has been removed, if it was the defailt and you have others in your configuration you will need to select it using kubectl configuration set-context context-name"
    
fi

echo "Deleting cluster api objects defined in $CAPI_YAML"
kubectl --context $KUBE_CONTEXT delete -f $CAPI_YAML

echo "Removing target namespace"
if ["$CAPI_CLUSTER_NAMESPACE_REUSED" = "true" ]
then
  echo "Capi cluster namespace was not created by these scripts, not deleting"
else
  echo "Capi cluster namespace was created by these scripts, deleting"
  kubectl --context $KUBE_CONTEXT delete namespace $CAPI_CLUSTER_NAMESPACE
fi

echo "Removing $CAPI_YAML"
rm $CAPI_YAML

bash ../delete-from-saved-settings.sh CAPI_NAMESPACE_REUSED
echo "$CAPI_REUSED_NAME=false" >> $SETTINGS