#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi


if [ $# -ge 0 ]
then
  CLUSTER_CONTEXT_NAME=$0
  echo "$SCRIPT_NAME Operating on supplied context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings, cannot continue"
    exit 10
fi

CONFIG_DIR=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf
STOCKMANAGER_CONFIG=$CONFIG_DIR/stockmanager-config.yaml
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Remove the configured the stockmanager config in $STOCKMANAGER_CONFIG defaults to $REPLY"
else
  echo "Remove the configured the stockmanager config in $STOCKMANAGER_CONFIG ."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
fi
if [ -f "$STOCKMANAGER_CONFIG" ]
then
    echo "Removing the configured the stockmanager config in $STOCKMANAGER_CONFIG"
    rm $STOCKMANAGER_CONFIG
else
    echo "Stock mamager config in $STOCKMANAGER_CONFIG already removed"
fi