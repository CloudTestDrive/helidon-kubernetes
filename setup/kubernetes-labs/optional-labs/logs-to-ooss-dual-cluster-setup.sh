#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -eq 0 ]
then
  CLUSTER_CONTEXT_NAME_ONE=one
  CLUSTER_CONTEXT_NAME_TWO=two
  echo "$SCRIPT_NAME using default cluster contexts of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
elif [ $# -eq 1 ]
  CLUSTER_CONTEXT_NAME_ONE=$1
  CLUSTER_CONTEXT_NAME_TWO=two
  echo "$SCRIPT_NAME using provided cluster contexts of $CLUSTER_CONTEXT_NAME_ONE and default cluster context of $CLUSTER_CONTEXT_NAME_TWO"
else
  CLUSTER_CONTEXT_NAME_ONE=$1
  CLUSTER_CONTEXT_NAME_TWO=$2
  echo "$SCRIPT_NAME using provided cluster contexts of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
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
SAVED_DIR=`pwd`
cd $HOME/helidon-kubernetes/setup/common/secret-keys
bash ./secret-key-setup.sh "$KEY_NAME"
cd $SAVED_DIR

bash ./logs-to-ooss-fluentd-setup.sh "$KEY_NAME" $CLUSTER_CONTEXT_NAME_ONE
bash ./logs-to-ooss-fluentd-setup.sh "$KEY_NAME" $CLUSTER_CONTEXT_NAME_TWO