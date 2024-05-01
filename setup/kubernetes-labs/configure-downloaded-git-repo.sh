#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
DEPARTMENT=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on supplied context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
REPO_CONFIGURED_FOR_SERVICES_NAME=`bash ../common/settings/to-valid-name.sh "REPO_CONFIGURED_FOR_SERVICES"_"$CLUSTER_CONTEXT_NAME"`
if [ -z "${!REPO_CONFIGURED_FOR_SERVICES_NAME}" ]
then
  echo "Configuring the repo for the database and other settings"
else
  echo "The repo has already been configured for the database and other configuration information for this cluster, run the unconfigure-downloaded-git-repo.sh to reset this"
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
bash ./set-stockmanager-config-department.sh $DEPARTMENT $CLUSTER_CONTEXT_NAME
bash ./install-db-wallet.sh $HOME/Wallet.zip $CLUSTER_CONTEXT_NAME
DB_CONNECTION_NAME=`bash ./get-database-connection-name.sh`
bash ./set-database-connection-secret.sh $DB_CONNECTION_NAME $CLUSTER_CONTEXT_NAME

# Flag that we've configured things
echo "$REPO_CONFIGURED_FOR_SERVICES_NAME=true" >> $SETTINGS