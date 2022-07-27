#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1


export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings, cannot continue"
    exit 10
fi

if [ -z "$REPO_CONFIGURED_FOR_SERVICES" ]
then
  echo "The repo has already been unconfigured for the database and other configuration information, run the configure-downloaded-git-repo.sh to set them"
  exit 0
else
  echo "Unconfiguring the database and other settings from the repo"
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, unconfiguring up config in downloaded git repo using $DEPARTMENT as the department name defaults to $REPLY"
else
  echo "unconfiguring downloaded git repo using $DEPARTMENT as the department name"
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

# flag that we've unconfigured things
bash ../common/delete-from-saved-settings.sh REPO_CONFIGURED_FOR_SERVICES