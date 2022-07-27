#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
DB_NAME=$1
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
  echo "Auto confirm enabled, Updating the database connection secret config to reset $dbname as the database connection defaults to $REPLY"
else
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Resetting database connection secret"
fi
DB_SECRET=$HOME/helidon-kubernetes/configurations/stockmanagerconf/databaseConnectionSecret.yaml
TEMP="$DB_SECRET".tmp
echo "Updating the database connection secret config in $config to reset $dbname as the database connection"
# echo command is "s/$DB_NAME/<database connection name>/"
cat $DB_SECRET | sed -e "s/$DB_NAME/<database connection name>/" > $TEMP
rm $DB_SECRET
mv $TEMP $DB_SECRET