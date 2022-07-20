#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. Tims"
    exit -1 
fi
department=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
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

if [ -z "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" ]
then
  export KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES=0
fi

if [ "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" = 0 ]
then
  echo "No other clusters with shared services currently installed, will reset the department config file"
else
  echo "There are other clusters with the shared services remaining, no need to reset the department config files"
  exit 0
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the stockmanager config to reset $department as the department name defaults to $REPLY"
else
  echo "Updating the stockmanager config to reset $department as the department name."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Department reset using $department as the department name"
fi
config=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf/stockmanager-config.yaml
temp="$config".tmp
echo "Updating the stockmanager config in $config to reset $department as the department name"
# echo command is "s/  department: \"$department Shop\"/#  department: \"My Shop\"/"
cat $config | sed -e "s/  department: \"$department Shop\"/#  department: \"My Shop\"/" > $temp
rm $config
mv $temp $config