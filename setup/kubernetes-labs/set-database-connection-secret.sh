#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
DB_CONNECTION_NAME=$1
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection defaults to $REPLY"
else
  echo "Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection"
fi
DB_CONNECTION_SECRET_YAML=$HOME/helidon-kubernetes/configurations/stockmanagerconf/databaseConnectionSecret.yaml
TEMP="$DB_CONNECTION_SECRET_YAML".tmp
echo "Updating the database connection secret config in $DB_CONNECTION_SECRET_YAML to set $DB_CONNECTION_NAME as the database connection"
# echo command is "s/<database connection name>/$DB_CONNECTION_NAME/"
cat $DB_CONNECTION_SECRET_YAML | sed -e "s/<database connection name>/$DB_CONNECTION_NAME/" > $TEMP
rm $DB_CONNECTION_SECRET_YAML
mv $TEMP $DB_CONNECTION_SECRET_YAML