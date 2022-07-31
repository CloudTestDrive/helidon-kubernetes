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

echo "Destroying logging namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl delete namespace logging  --ignore-not-found=true  --context $CLUSTER_CONTEXT_NAME

S3_CONFIGURED_YAML=fluentd-s3-configmap-$CLUSTER_CONTEXT_NAME.yaml
if [ -f "$S3_CONFIGURED_YAML" ]
then
  echo "Removing modified config map file"
  rm $S3_CONFIGURED_YAML
fi

cd $HOME/helidon-kubernetes/setup/common/object-storage

BUCKET_NAME=`echo "LOGGING_FLUENTD_""$USER_INITIALS""_""$CLUSTER_CONTEXT_NAME" | tr [:lower:] [:upper:]`

bash ./object-storage-bucket-destroy.sh $BUCKET_NAME