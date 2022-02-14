#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. Tims"
    exit -1 
fi
department=$1
if [ $# -eq 1 ]
  then
    echo setting up config in downloaded git repo using $department as the department name and $HOME/Wallet.zip as the DB wallet file.
    read -p "Proceed ? "
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping configure-repo confirmation using $department as the deparment name and $HOME/Wallet.zip as the DB wallet file"
fi
# run the config setup - note that the skips tell the sub scripts not to ask for confirmation
bash ./set-stockmanager-config-department.sh $department skip
bash ./install-db-wallet.sh $HOME/Wallet.zip skip
dbConnection=`bash ./get-database-connection-name.sh`
bash ./set-database-connection-secret.sh $dbConnection skip