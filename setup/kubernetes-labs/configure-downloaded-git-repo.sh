#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME, Missing arguments :"
    echo "  1st argument is the name of your department, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z "$REPO_CONFIGURED_FOR_SERVICES" ]
then
  echo "Configuring the repo for the database and other settings"
else
  echo "The repo has already been configured for the database and other configuration information, run the unconfigure-downloaded-git-repo.sh to reset this"
  exit 0
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, setting up config in downloaded git repo using $DEPARTMENT as the department name and $HOME/Wallet.zip as the DB wallet file. defaulting to $REPLY"
else
  echo "setting up config in downloaded git repo using $DEPARTMENT as the department name and $HOME/Wallet.zip as the DB wallet file."
  read -p "Proceed (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Using $DEPARTMENT as the deparment name and $HOME/Wallet.zip as the DB wallet file"
fi
# run the config setup - note that the skips tell the sub scripts not to ask for confirmation
bash ./set-stockmanager-config-department.sh $DEPARTMENT
bash ./install-db-wallet.sh $HOME/Wallet.zip 
DB_CONNECTION_NAME=`bash ./get-database-connection-name.sh`
bash ./set-database-connection-secret.sh $DB_CONNECTION_NAME

# Flag that we've configured things
echo "REPO_CONFIGURED_FOR_SERVICES=true" >> $SETTINGS