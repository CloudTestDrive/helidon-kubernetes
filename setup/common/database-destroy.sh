#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z $DATABASE_REUSED ]
then
  echo "No reuse information for database safely cannot continue, you will have to destroy it manually"
  exit 0
fi

if [ $DATABASE_REUSED = true ]
then
  echo "$SCRIPT_NAME You have been using a database that was not created by these scripts, you will need to destroy the database by hand"
  echo "and then remove DATABASE_REUSE and DATABASE_OCID from $SETTINGS "
  exit 0
fi

if [ -z $DB_OCID ]
then 
  echo "$SCRIPT_NAME No Database OCID information found, cannot destroy something that cannot be identifed"
  exit 3
fi

DBNAME=`oci db autonomous-database get --autonomous-database-id $DB_OCID | jq -j '.data."display-name"'`
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, destroy database $DBNAME defaulting to $REPLY"
else
  read -p "Are you sure you want to destroy the database $DBNAME and data it contains (y/n) ? " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not detroying database"
else
  echo "Terminating database $DBNAME this may take a while"
  oci db autonomous-database delete --autonomous-database-id $DB_OCID --force

  bash ./delete-from-saved-settings.sh DB_OCID
  bash ./delete-from-saved-settings.sh DATABASE_REUSED
  bash ./delete-from-saved-settings.sh DATABASE_ADMIN_PASSWORD
  
  if [ -z "$DB_WALLET_REUSED" ]
  then
    echo "No reuse information regarding the downloaded database wallet, will not attempt to remove it"
  else  
    if [ "$DB_WALLET_REUSED" = "true" ]
    then
      echo "The database wallet file is reused, will not attempt to delete it"
    else
      echo "Checking if the DB Wallet needs removing"
      if [ -z "$DB_WALLET_LOCATION" ]
      then
        echo "No stored location of the database wallet, can't remove it"
      else
        if [ -f "$DB_WALLET_LOCATION" ]
        then
          echo "Deleting $DB_WALLET_LOCATION"
          rm $DB_WALLET_LOCATION
        else
          echo "Can't locate $DB_WALLET_LOCATION for removal, if it's been renamed please remove it manually"
        fi
      fi
    fi
  fi
  bash ./delete-from-saved-settings.sh DB_WALLET_LOCATION
  bash ./delete-from-saved-settings.sh DB_WALLET_REUSED
fi