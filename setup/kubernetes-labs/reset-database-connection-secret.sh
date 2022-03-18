#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi
dbname=$1
if [ $# -eq 1 ]
  then
    echo "Updating the database connection secret config to reset $dbname as the database connection."
    read -p "Proceed ? "
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