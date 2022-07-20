#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
dbname=$1
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
  echo "No other clusters with shared services currently installed, will setup the database connection config file"
else
  echo "There are other clusters with the shared services already in place, no need to update the database connection config file"
  exit 0
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the database connection secret config to set $dbname as the database connection defaults to $REPLY"
else
  echo "Updating the database connection secret config to set $dbname as the database connection."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Updating the database connection secret config to set $dbname as the database connection"
fi
config=$HOME/helidon-kubernetes/configurations/stockmanagerconf/databaseConnectionSecret.yaml
temp="$config".tmp
echo "Updating the database connection secret config in $config to set $dbname as the database connection"
# echo command is "s/<database connection name>/$dbname/"
cat $config | sed -e "s/<database connection name>/$dbname/" > $temp
rm $config
mv $temp $config