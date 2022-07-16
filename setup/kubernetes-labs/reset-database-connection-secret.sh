#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
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
  echo "No other clusters with shared services currently installed, will reset the database connection config file"
else
  echo "There are other clusters with the shared services already in place, no need to reset the database connection config file"
  exit 0
fi

if [ $# -eq 1 ]
  then
    echo "Updating the database connection secret config to reset $dbname as the database connection."
    read -p "Proceed (y/n) ?"
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping database connection secret confirmation"
fi
config=$HOME/helidon-kubernetes/configurations/stockmanagerconf/databaseConnectionSecret.yaml
temp="$config".tmp
echo "Updating the database connection secret config in $config to reset $dbname as the database connection"
# echo command is "s/$dbname/<database connection name>/"
cat $config | sed -e "s/$dbname/<database connection name>/" > $temp
rm $config
mv $temp $config