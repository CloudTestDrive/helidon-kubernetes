#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. tg"
    exit -1 
fi
department=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, unconfiguring up config in downloaded git repo using $DEPARTMENT as the department name defaults to $REPLY"
else
  echo "unconfiguring up config in downloaded git repo using $DEPARTMENT as the department name"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Resetting downloaded git repo"
fi
# run the config setup - note that the skips tell the sub scripts not to ask for confirmation

DB_CONNECTION=`bash ./get-database-connection-name.sh`

bash ./reset-database-connection-secret.sh $DB_CONNECTION 
bash ./uninstall-db-wallet.sh $HOME/Wallet.zip 
bash ./reset-stockmanager-config-department.sh $DEPARTMENT 