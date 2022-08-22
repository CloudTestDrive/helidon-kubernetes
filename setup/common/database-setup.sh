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

if [ -z $USER_INITIALS ]
then
  echo "$SCRIPT_NAME Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo "$SCRIPT_NAME Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

# can set DB_TYPE to DW if you want a data warehouse
if [ -z "$DB_TYPE" ]
then
  export DB_TYPE=OLTP
fi

if [ -z $DATABASE_REUSED ]
then
  echo "No reuse information for database"
else
  echo "This script has already configured database details, they will be reused"
  echo "If you need to reset them use the database-destroy.sh script"
  exit 0
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS"
  exit 99
else
  echo "Operating in compartment $COMPARTMENT_NAME"
fi

DBNAME="$USER_INITIALS"db

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, using $DBNAME for database defaulting to $REPLY"
else
  read -p "Do you want to use $DBNAME as the name of the databse to create or re-use in $COMPARTMENT_NAME (y/n) ?" REPLY
fi

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
if [ -z $DB_OCID ]
  then
  # No existing DB_OCID so need to potentially create it, even if it exists will assume we need to get the wallet and setup the labs user
  echo "Checking for database $DBNAME in compartment $COMPARTMENT_NAME"
  DB_OCID=`oci db autonomous-database list --compartment-id $COMPARTMENT_OCID --display-name $DBNAME --lifecycle-state AVAILABLE | jq -j '.data[0].id'`

  if [ -z "$DB_OCID" ]
  then
     echo "Database named $DBNAME doesn't exist, creating it, there may be a few minutes delay"
     DB_ADMIN_PW=`date | cksum | awk -e '{print $1}'`_SeCrEt
     DB_OCID=`oci db autonomous-database create --db-name $DBNAME --display-name $DBNAME --db-workload $DB_TYPE --admin-password $DB_ADMIN_PW --compartment-id $COMPARTMENT_OCID --license-model BRING_YOUR_OWN_LICENSE --cpu-core-count 1 --data-storage-size-in-tbs  1  --wait-for-state AVAILABLE --wait-interval-seconds 10 | jq -j '.data.id'`
     echo "DB_OCID=$DB_OCID" >> $SETTINGS
     echo "DATABASE_REUSED=false" >> $SETTINGS
     if [ "$AUTO_CONFIRM" = true ]
     then
       REPLY="y"
       echo "Auto confirm is enabled, save db password $DBNAME for database defaulting to $REPLY"
     else
       read -p "Do you want to save the database admin password to $SETTINGS ?" REPLY
     fi
     if [[ ! $REPLY =~ ^[Yy]$ ]]
     then
       echo "OK, not saving DB password, please ensure that you remember $DB_ADMIN_PW if you want to admin it in the future"
     else
       echo "OK, saving DB admin password"
       echo "DATABASE_ADMIN_PASSWORD=$DB_ADMIN_PW" >> $SETTINGS
     fi
     echo "Database creation started"
     echo "The generated database admin password is $DB_ADMIN_PW Please ensure that you save this information in case you need it later"
  else
     echo "Database named $DBNAME already exists"
     echo "To use this database please enter the database admin password (this will only be used to confiure the database labs used and will not be saved)"
     read DB_ADMIN_PW
     if [ -z "$DB_OCID" ]
     then
       echo "You must enter the database ADMIN password for database $DBNAME cannot progress without that, please re-run this script and enter the password"
       exit 4
     fi
     echo "DATABASE_REUSED=true" >> $SETTINGS
  fi


  echo "Downloading DB Wallet file"
  echo "There may be a delay of several minutes while the database completes it's creation process, don't worry."

  DB_WALLET_LOCATION=$HOME/Wallet.zip
  if [ -f "$DB_WALLET_LOCATION" ]
  then
    echo "There is already a downloaded Wallet file in $DB_WALLET_LOCATION"
    echo "Moving old $DB_WALLET_LOCATION file to Orig-$DB_WALLET_LOCATION"
    mv $DB_WALLET_LOCATION Orig-$DB_WALLET_LOCATION
  fi
  echo "About to download Database wallet to $DB_WALLET_LOCATION"
  oci db autonomous-database generate-wallet --file $DB_WALLET_LOCATION --password 'Pa$$w0rd' --autonomous-database-id $DB_OCID
  echo "Downloaded database Wallet file"

  echo "DB_WALLET_LOCATION=$DB_WALLET_LOCATION" >> $SETTINGS
  echo "DB_WALLET_REUSED=false" >> $SETTINGS

  
  echo "Preparing temporary database connection details"

  echo "Getting wallet contents for temporaty processing"
  TMPWALLET=`pwd`/tmpwallet
  mkdir -p $TMPWALLET
  cp $DB_WALLET_LOCATION $TMPWALLET
  cd $TMPWALLET
  unzip Wallet.zip

  echo "Updating temporary sqlnet.ora"
  SQLNET=sqlnet.ora
  cat $SQLNET | sed -e "s:\?/network/admin:$TMPWALLET:" > tmp-$SQLNET
  mv $SQLNET orig-$SQLNET
  mv tmp-$SQLNET $SQLNET

  cd ..

  export TNS_ADMIN=$TMPWALLET

  echo "Connecting to database to create labs user"

  sqlplus ADMIN/$DB_ADMIN_PW@"$DBNAME"_high @setup-db-user.sql

  echo "Deleting temporary database connection info"

  rm -rf $TMPWALLET
  
  # save the ADB ID away
  echo "DB_OCID=$DB_OCID" >> $SETTINGS
  if [ -z $DB_ADMIN_PW ]
  then
    echo "No saved DB password"
  else
    echo "The database admin password is $DB_ADMIN_PW Please ensure that you save this information in case you need it later"
  fi
else
  # We'de been given an ATB OCID, let's check if it's there, if so assume it's been configured already
  DBNAME=`oci db autonomous-database get --autonomous-database-id $DB_OCID | jq -j '.data."display-name"'`
  if [ -z $DBNAME ]
  then
    echo "Unable to locate databse for OCID $DB_OCID "
    echo "Please check that the value of DB_OCID in $SETTINGS is correct if nor remove or replace it"
    exit 5
  else
    echo "Located database named $DBNAME with pre-specified OCID of $DB_OCID, will use this database"
    if [ -f "$DB_WALLET_LOCATION" ]
    then
      echo "There is no database wallet file at $DB_WALLET_LOCATION, you will need to download the database wallet to this location"
    else
      echo "Assuming the database wallet file at $DB_WALLET_LOCATION relates to this database" 
      echo "DB_WALLET_REUSED=true" >> $SETTINGS
    fi
    echo "It is assumed you have created the db user for the labs by hand or using this script"
    # Flag this as reused and refuse to destroy it
    echo "DATABASE_REUSED=true" >> $SETTINGS
  fi
fi
