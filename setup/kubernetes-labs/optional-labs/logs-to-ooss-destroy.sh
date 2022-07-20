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


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "Destroying logging namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl delete namespace logging  --ignore-not-found=true  --context $CLUSTER_CONTEXT_NAME

echo "Removing Certificates"
SAVE_DIR=`pwd`
cd $HOME/helidon-kubernetes/management/logging
# make sure there is something to delete
touch tls-deleteme.crt
touch tls-deleteme.key
# delete them
rm tls-*.crt
rm tls-*.key

echo "Removing modified config map file"
touch fluentd-s3-configmap-configured.yaml
rm fluentd-s3-configmap-configured.yaml

echo "Removing auth file"
touch auth
rm auth

SAVED_DIR=`pwd`
echo "Trying to delete secret key"
cd $HOME/helidon-kubernetes/setup/common/secret-keys
KEY_NAME="LoggingLabsTestKey"
bash ./secret-key-destroy.sh $KEY_NAME


if [ -z "$LOGGING_OOSS_BUCKET_NAME" ]
then
  echo "No name info for the storage bucket, cannot proceed"
  exit 0
else
  echo "Deleting bucket $LOGGING_OOSS_BUCKET_NAME"
fi

oci os bucket delete --bucket-name $LOGGING_OOSS_BUCKET_NAME --empty --force
cd $HOME/helidon-kubernetes/setup/common
bash ./delete-from-settings.sh LOGGING_OOSS_BUCKET_NAME
