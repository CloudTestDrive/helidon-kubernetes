#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department, e.g. Tims"
    exit -1 
fi
department=$1
if [ $# -eq 1 ]
  then
    echo "unconfiguring up config in downloaded git repo using $department as the department name"
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

dbConnection=`bash ./get-database-connection-name.sh`

bash ./reset-database-connection-secret.sh $dbConnection skip
bash ./uninstall-db-wallet.sh $HOME/Wallet.zip skip
bash ./reset-stockmanager-config-department.sh $department skip