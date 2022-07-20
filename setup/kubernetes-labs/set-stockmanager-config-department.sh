#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1

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
if [ -z "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" ]
then
  export KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES=0
fi

if [ "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" = 0 ]
then
  echo "No other clusters with shared services currently installed, will setup the department config file"
else
  echo "There are other clusters with the shared services already in place, no need to update the department config file"
  exit 0
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
STOCKMANAGER_CONFIG=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf/stockmanager-config.yaml
TEMP="$STOCKMANAGER_CONFIG".tmp
echo "Updating the stockmanager config in $STOCKMANAGER_CONFIG to reset $DEPARTMENT as the department name"
# echo command is "s/#  department: \"My Shop\"/  department: \"$DEPARTMENT Shop\"/"
cat $STOCKMANAGER_CONFIG | sed -e "s/#  department: \"My Shop\"/  department: \"$DEPARTMENT Shop\"/" > $TEMP
rm $STOCKMANAGER_CONFIG
mv $TEMP $STOCKMANAGER_CONFIG