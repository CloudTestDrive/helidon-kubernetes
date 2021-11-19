#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

if [ -z $DATABASE_REUSED ]
then
  echo No reuse information for database safely cannot continue, you will have to destroy it manually
  exit 1
fi

if [ $DATABASE_REUSED = true ]
then
  echo You have been using a database that was not created by these scripts, you will need to destroy the cluster by hand
  echo then remove DATABASE_REUSE and DATABASE_OCID from $SETTINGS 
  exit 2
fi

if [ -z $ATPDB_OCID ]
then 
  echo No Database OCID information found, cannot destroy something that cant be identifed
  exit 3
fi

DBNAME=`oci db autonomous-database get --autonomous-database-id $ATPDB_OCID | jq -j '.data."display-name"'`

echo Terminating database $DBNAME this may take a while
oci db autonomous-database delete --autonomous-database-id $ATPDB_OCID

bash ./delete-from-saved-settings.sh ATPDB_OCID
bash ./delete-from-saved-settings.sh DATABSE_REUSED