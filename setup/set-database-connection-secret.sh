#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi
if [ $# -eq 1 ]
  then
    echo Updating the database connection secret config to set $1 as the database connection.
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping confirmation"
fi
config=$HOME/helidon-kubernetes/configurations/stockmanagerconf/databaseConnectionSecret.yaml
temp="$config".tmp
echo Updating the database connection secret config in $config to set $1 as the database connection
echo command is "s/<database connection name>/$1/"
cat $config | sed -e "s/<database connection name>/$1/" > $temp
rm $config
mv $temp $config