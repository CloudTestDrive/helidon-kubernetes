#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st the name of your DEPARTMENT, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings, cannot continue"
    exit 10
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the stockmanager config to reset $DEPARTMENT as the department name defaults to $REPLY"
else
  echo "Updating the stockmanager config to reset $DEPARTMENT as the department name."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Department reset using $DEPARTMENT as the department name"
fi
STOCKMANAGER_CONFIG=$HOME/helidon-kubernetes/configurations/stockmanagerconf/conf/stockmanager-config.yaml
TEMP="$STOCKMANAGER_CONFIG".tmp
echo "Updating the stockmanager config in $STOCKMANAGER_CONFIG to reset $DEPARTMENT as the department name"
# echo command is "s/  department: \"$DEPARTMENT Shop\"/#  department: \"My Shop\"/"
cat $STOCKMANAGER_CONFIG | sed -e "s/  department: \"$DEPARTMENT Shop\"/#  department: \"My Shop\"/" > $TEMP
rm $STOCKMANAGER_CONFIG
mv $TEMP $STOCKMANAGER_CONFIG