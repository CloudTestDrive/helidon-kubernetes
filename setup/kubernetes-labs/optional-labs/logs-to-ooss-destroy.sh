#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "Destroying logging namespace"
kubectl delete namespace logging  --ignore-not-found=true

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
fi

oci os bucket delete --bucket-name $LOGGING_OOSS_BUCKET_NAME --empty --force
cd $HOME/helidon-kubernetes/setup/common
bash ../delete-from-settings.sh LOGGING_OOSS_BUCKET_NAME
