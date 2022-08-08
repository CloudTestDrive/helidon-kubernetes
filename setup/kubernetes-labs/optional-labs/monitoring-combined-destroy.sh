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


MONITORING_INSTALLED_NAME=`bash ../../common/settings/to-valid-name.sh "MONITORING_INSTALLED_""$CLUSTER_CONTEXT_NAME"`
MONITORING_INSTALLED="${!MONITORING_INSTALLED_NAME}"
if [ -z "$MONITORING_INSTALLED" ]
then
  echo "These scripts have not installed the monitoring previously for cluster $CLUSTER_CONTEXT_NAME, cannot continue"
  exit 0
else
  echo "These have previously installed the monitoring for cluster $CLUSTER_CONTEXT_NAME will remove"
fi

echo "Destroying monitoring namespace in cluster $CLUSTER_CONTEXT_NAME"
kubectl delete namespace monitoring  --ignore-not-found=true  --context $CLUSTER_CONTEXT_NAME

echo "Removing Certificates"

SAVED_DIR=`pwd`
cd $HOME/helidon-kubernetes/monitoring-kubernetes
# make sure there is something to delete
touch tls-deleteme.crt
touch tls-deleteme.key
# delete them
rm tls-*.crt
rm tls-*.key

if [ -f auth.$CLUSTER_CONTEXT_NAME ]
then
  echo "Removing file auth.$CLUSTER_CONTEXT_NAME "
  rm auth.$CLUSTER_CONTEXT_NAME
else
  echo "Cannot locate the auth.$CLUSTER_CONTEXT_NAME file to remove"
fi
cd $SAVED_DIR
bash ../../common/delete-from-saved-settings.sh $LOGGING_INSTALLED_NAME