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

if [ -z $USER_INITIALS ]
then
  echo Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 2
fi


if [ -z $DATABASE_REUSED ]
then
  echo No reuse information for database
else
  echo This script has already configured database details, exiting
  exit 3
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS
  exit 99
else
  echo Operating in compartment $COMPARTMENT_NAME
fi

DBNAME="$USER_INITIALS"db

read -p "Do you want to use $DBNAME as the name of the databse to create or re-use in $COMPARTMENT_NAME?" REPLY

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the name of the database to create / re-use, it must be a single word, e.g. TGDemo"
  read DBNAME
  if [ -z "$DBNAME" ]
  then
    echo "You do actually need to enter the new name for the database, exiting"
    exit 1
  fi
else     
  echo "OK, going to use $DBNAME as the database name"
fi

#allow for re-using an existing database
if [ -z $ATPDB_OCID ]
  then
  # No existing ATPDB_OCID so need to potentially create it, even if it exists will assume we need to get the wallet and setup the labs user
  echo Checking for database $DBNAME in compartment $COMPARTMENT_NAME
  ATPDB_OCID=`oci db autonomous-database list --compartment-id $COMPARTMENT_OCID --display-name $DBNAME | jq -j '.data[0].id'`

  if [ -z "$ATPDB_OCID" ]
  then
     echo "Database named $DBNAME doesn't exist, creating it, there may be a short delay"
     DB_ADMIN_PW=`date | cksum | awk -e '{print $1}'`_SeCrEt
     ATPDB_OCID=`oci db autonomous-database create --db-name $DBNAME --display-name $DBNAME --db-workload OLTP --admin-password $DB_ADMIN_PW --compartment-id $COMPARTMENT_OCID --license-model BRING_YOUR_OWN_LICENSE --cpu-core-count 1 --data-storage-size-in-tbs  1 | jq -j '.data.id'`
     echo ATPDB_OCID=$ATPDB_OCID >> $SETTINGS
     echo DATABASE_REUSED=false >> $SETTINGS
     echo The generated database admin password is $DB_ADMIN_PW Please ensure that you save this information in case you need it later
  else
     echo "Database named $DBNAME already exists"
     echo "To use this database please enter the database admin password (this will only be used to confiure the database labs used and will not be saved)"
     read DB_ADMIN_PW
     if [ -z "$ATPDB_OCID" ]
     then
       echo You must enter the database ADMIN password for database $DBNAME cannot progress without that, please re-run this script and enter the password
       exit 4
     fi
     echo DATABASE_REUSED=true >> $SETTINGS
  fi


  echo Downloading DB Wallet file

  if [ -f $HOME/Wallet.zip ]
  then
    echo "There is already a downloaded Wallet file in $HOME/Wallet.zip"
    echo Moving old $HOME/Wallet.zip file to $HOME/Wallet-orig.zip
    mv $HOME/Wallet.zip $HOME/Wallet-orig.zip
  fi
  echo "About to download Database wallet to $HOME/Wallet.zip"
  oci db autonomous-database generate-wallet --file $HOME/Wallet.zip --password 'Pa$$w0rd' --autonomous-database-id $ATPDB_OCID
  echo Downloaded Wallet.zip file


  
  echo Preparing temporary database connection details

  echo Getting wallet contents for temporaty processing
  TMPWALLET=`pwd`/tmpwallet
  mkdir -p $TMPWALLET
  cp $HOME/Wallet.zip $TMPWALLET
  cd $TMPWALLET
  unzip Wallet.zip

  echo updating temporary sqlnet.ora
  SQLNET=sqlnet.ora
  cat $SQLNET | sed -e "s:\?/network/admin:$TMPWALLET:" > tmp-$SQLNET
  mv $SQLNET orig-$SQLNET
  mv tmp-$SQLNET $SQLNET

  cd ..

  export TNS_ADMIN=$TMPWALLET

  echo Connecting to database to create labs user

  sqlplus ADMIN/$DB_ADMIN_PW@"$DBNAME"_high @setup-db-user.sql

  echo Deleting temporary database connection info

  rm -rf $TMPWALLET
  
  # save the ADB ID away
  echo ATPDB_OCID=$ATPDB_OCID >> $SETTINGS
else
  # We'de been given an ATB OCID, let's check if it's there, if so assume it's been configured already
  DBNAME=`oci db autonomous-database get --autonomous-database-id $ATPDB_OCID | jq -j '.data."display-name"'`
  if [ -z $DBNAME ]
  then
    echo Unable to locate databse for OCID $ATPDB_OCID 
    echo Please check that the value of ATPDB_OCID in $SETTINGS is correct if nor remove or replace it
    exit 5
  else
    echo Located database named $DBNAME with pre-specified OCID of $ATPDB_OCID, will use this database
    echo It is assumed you have downloaded this database wallet to $HOME/Wallet.zip by hand or using this script
    echo It is assumed you have created the db user for the labs by hand or using this script
    # Flag this as reused and refuse to destroy it
    echo DATABASE_REUSED=true >> $SETTINGS
  fi
fi
