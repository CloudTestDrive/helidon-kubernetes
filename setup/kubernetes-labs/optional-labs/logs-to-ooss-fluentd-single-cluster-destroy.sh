#!/bin/bash -f

SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
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

source logs-to-ooss-fluentd-settings.sh

bash ./logs-to-ooss-fluentd-destroy.sh  $CLUSTER_CONTEXT_NAME
SAVED_DIR=`pwd`
cd $HOME/helidon-kubernetes/setup/common/secret-keys
bash ./secret-key-destroy.sh "$KEY_NAME"
cd $SAVED_DIR