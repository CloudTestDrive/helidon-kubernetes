#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. Tims"
    exit -1 
fi
if [ $# -eq 1 ]
  then
    echo Updating the stockmanager config to set $1 as the department name.
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
config=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf/stockmanager-config.yaml
temp="$config".tmp
echo Updating the stockmanager config in $config to set $1 as the department name
echo command is "s/#  department: \"My Shop\"/  department: \"$1 Shop\"/"
cat $config | sed -e "s/#  department: \"My Shop\"/  department: \"$1 Shop\"/" > $temp
rm $config
mv $temp $config