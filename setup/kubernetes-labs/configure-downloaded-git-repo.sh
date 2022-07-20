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
  echo "Auto confirm enabled, setting up config in downloaded git repo using $department as the department name and $HOME/Wallet.zip as the DB wallet file. defaulting to $REPLY"
else
  echo "setting up config in downloaded git repo using $department as the department name and $HOME/Wallet.zip as the DB wallet file."
  read -p "Proceed (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Using $department as the deparment name and $HOME/Wallet.zip as the DB wallet file"
fi
# run the config setup - note that the skips tell the sub scripts not to ask for confirmation
bash ./set-stockmanager-config-department.sh $department skip
bash ./install-db-wallet.sh $HOME/Wallet.zip skip
dbConnection=`bash ./get-database-connection-name.sh`
bash ./set-database-connection-secret.sh $dbConnection skip