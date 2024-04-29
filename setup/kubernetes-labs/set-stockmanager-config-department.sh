#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
DEPARTMENT=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi


if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on supplied context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "Loading existing settings"
  source $SETTINGS
else 
  echo "No existing settings, cannot continue"
  exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the stockmanager config to set $DEPARTMENT as the department name. defaults to $REPLY"
else
  echo "Updating the stockmanager config to set $DEPARTMENT as the department name."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Setting stockmanager department using $DEPARTMENT as the department name"
fi

CONFIG_DIR=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf
STOCKMANAGER_CONFIG_TEMPLATE=$CONFIG_DIR/stockmanager-config-template.yaml
STOCKMANAGER_CONFIG=$CONFIG_DIR/stockmanager-config.yaml
TEMP="$STOCKMANAGER_CONFIG".tmp
echo "Updating the stockmanager config in $STOCKMANAGER_CONFIG to reset $DEPARTMENT as the department name"
# echo command is "s/#  department: \"My Shop\"/  department: \"$DEPARTMENT Shop\"/"
cat $STOCKMANAGER_CONFIG_TEMPLATE | sed -e "s/#  department: \"My Shop\"/  department: \"$DEPARTMENT Shop\"/" > $TEMP
if [ -f "$STOCKMANAGER_CONFIG" ]
then
   echo "Removing old $STOCKMANAGER_CONFIG file"
   rm $DB_CONNECTION_SECRET_YAML
else
   echo "No old STOCKMANAGER_CONFIG file to remove" 
fi
rm $STOCKMANAGER_CONFIG
mv $TEMP $STOCKMANAGER_CONFIG