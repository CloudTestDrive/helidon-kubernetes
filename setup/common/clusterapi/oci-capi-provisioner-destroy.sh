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
  echo "capi provisioner reuse information not found, cannot continue"
  exit 0
else
  echo "capi provisioner reuse info found, continuing"
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
CAPI_PROVISIONER_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_PROVISIONER_"$CLUSTER_CONTEXT_NAME"_REUSED"`
CAPI_PROVISIONER_REUSED="${!CAPI_PROVISIONER_REUSED_NAME}"
if [ -z "$CAPI_PROVISIONER_REUSED" ]
then
  echo "No reuse information for CAPI in cluster $CLUSTER_CONTEXT_NAME cannot continue"
  exit 1
else
  echo "Located CAPI rwuse information for cluster $CLUSTER_CONTEXT_NAME"
fi

if [ "$CAPI_PROVISIONER_REUSED" = "true" ]
then
  echo "Capi config for cluster $CLUSTER_CONTEXT_NAME was reused, not going to delete it."
  exit 0
else
  echo "Capi config for cluster $CLUSTER_CONTEXT_NAME was create by these scripts, proceding with removal."
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to delete the cluster api provider in kubernetes cluster $CLUSTER_CONTEXT_NAME defaulting to $REPLY"
else
  read -p "Do you want to delete the cluster api provider in kubernetes cluster $CLUSTER_CONTEXT_NAME (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not deleting"
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
echo "Deleting cluster API provisioner from cluster $CLUSTER_CONTEXT_NAME"

$CLUSTERCTL_PATH delete --infrastructure oci --include-namespace --include-crd

if [ "$CAPI_PROVISIONER_REUSED" = "true" ]
then
  echo "Capi directory $CAPI_DIR not created by this script, not removing"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Capi directory $CAPI_DIR was created by this script, delete it defaulting to $REPLY"
  else
    read -p "Capi directory $CAPI_DIR was created by this script, delete it (y/n) ? " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, will not delete $CAPI_DIR"
  else
    echo "OK, deleting $CAPI_DIR"
    # make sure it's there to delete
    mkdir -p $CAPI_DIR
    rm -rf $CAPI_DIR
  fi
fi
CAPI_NAMESPACE_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_PROVISIONER_NAMESPACE_"$CLUSTER_CONTEXT_NAME"_REUSED`
CAPI_NAMESPACE_REUSED="${!CAPI_NAMESPACE_REUSED_NAME}"
# do we need to delete the namespace ?
if [ -z "$CAPI_NAMESPACE_REUSED" ]
then
  echo "No resuse information on namespace $CAPI_NAMESPACE, cannot determine if it should be deleted"
else
  echo "Located namepace $CAPI_NAMESPACE resuse information"
  if [ "$CAPI_NAMESPACE_REUSED" = "true" ]
  then
    echo "Capi namespace $CAPI_NAMESPACE was reused, not deleting it"
  else
    echo "Capi namespace $CAPI_NAMESPACE was not reused, deleting it"
    kubectl delete namespace $CAPI_NAMESPACE --ignore-not-found=true
  fi
fi

CERT_MGR_NS=cert-manager
CERT_MGR_NS_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_CERT_MANAGER_NS_"$CLUSTER_CONTEXT_NAME"_REUSED"`
CERT_MGR_NS_REUSED="${!CERT_MGR_NS_REUSED_NAME}"
if [ -z "$CERT_MGR_NS_REUSED" ]
then
  echo "Can't fine any reuse info for the $CERT_MGR_NS namespace, this is OK"
else 
  if [ "$CERT_MGR_NS_REUSED" = "false" ]
  then
    echo "The namespace $CERT_MGR_NS didn't exist before the CAPI provisioner was installed, attempting to delete it"
    kubectl delete ns $CERT_MGR_NS --ignore-not-found=true
  else
    echo "The namespace $CERT_MGR_NS existed before the CAPI provisioner was installed, retaining it"
  fi
fi

# revert to the origional context
kubectl config use-context $ORIG_K8S_CONTEXT

echo "Reverted to context $ORIG_K8S_CONTEXT"

bash ../delete-from-saved-settings.sh $CAPI_NAMESPACE_REUSED_NAME
bash ../delete-from-saved-settings.sh $CAPI_PROVISIONER_REUSED_NAME