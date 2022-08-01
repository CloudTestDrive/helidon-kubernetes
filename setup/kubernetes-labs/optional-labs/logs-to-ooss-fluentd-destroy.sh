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


LOGGING_INSTALLED_NAME=`bash ../../common/settings/to-valid-name.sh "LOGGING_TO_OOSS_WITH_FLUENTD_""$CLUSTER_CONTEXT_NAME"`
LOGGING_INSTALLED="${!LOGGING_INSTALLED_NAME}"
if [-z "$LOGGING_INSTALLED" ]
then
  echo "These scripts have not installed the logging previously for cluster $CLUSTER_CONTEXT_NAME, not safe to continue"
  exit 0
else
  echo "These have previously installed the logging for cluster $CLUSTER_CONTEXT_NAME continuing with removal"
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
# we're in the object storage directory
bash ../delete-from-saved-settings.sh $LOGGING_INSTALLED_NAME