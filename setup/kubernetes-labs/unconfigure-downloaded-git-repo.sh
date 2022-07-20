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
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, unconfiguring up config in downloaded git repo using $department as the department name defaults to $REPLY"
else
  echo "unconfiguring up config in downloaded git repo using $department as the department name"
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

dbConnection=`bash ./get-database-connection-name.sh`

bash ./reset-database-connection-secret.sh $dbConnection skip
bash ./uninstall-db-wallet.sh $HOME/Wallet.zip skip
bash ./reset-stockmanager-config-department.sh $department skip