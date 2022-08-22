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
  echo "$SCRIPT_NAME Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

if [ -z $USER_OCID ]
then
  echo "$SCRIPT_NAME Your user OCID has not been set, you need to run the user-identity-setup.sh script before you can run this script"
  exit 1
fi

echo "Determining settings"

OCI_REGION_KEY=`oci iam region list --all | jq -e  ".data[]| select (.name == \"$OCI_REGION\")" | jq -j '.key' | tr [:upper:] [:lower:]`

OCIR_STOCKMANAGER_LOCATION=$OCI_REGION_KEY.ocir.io
OCIR_LOGGER_LOCATION=$OCI_REGION_KEY.ocir.io
OCIR_STOREFRONT_LOCATION=$OCI_REGION_KEY.ocir.io

OCI_USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`

OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

OCIR_BASE_NAME="$USER_INITIALS"_labs_base_repo

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, use $OCIR_BASE_NAME as the base for naming your repo defaulting to $REPLY"
else
  read -p "Do you want to use $OCIR_BASE_NAME as the base for naming your repo (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the base name of the container image repo to use, it must be a single word or multiple words separated by underscore , e.g. $OCIR_BASE_NAME It cannot just be your initials"
  echo "This script will create two repos based on that name for each of the microservices"
  read OCIR_BASE_NAME
  if [ -z "$OCIR_BASE_NAME" ]
  then
    echo "You do actually need to enter the new name for the container image repo, exiting"
    exit 1
  fi
  if [ $OCIR_BASE_NAME = $USER_INITIALS ]
  then
    echo "You cannot use just your initials for the base nane"
    echo "This script will stop, please run it again and if you want enter a different name"
    exit 2
  fi
else     
  echo "OK, going to use $OCIR_BASE_NAME as the container image repo name"
fi

if [ -z $AUTH_TOKEN ]
then
  echo "There is no saved auth token which is needed to log in to docker"
  read -p "Please enter a valid auth token for your account" AUTH_TOKEN
  if [ -z $AUTH_TOKEN ]
  then
    echo "You did not enter an auth token, this script cannot proceed without that"
    echo "Script stopping"
    exit 4
  fi
else
  echo "Using the saved auth token for the docker login"
fi

COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`


if [ -z $OCIR_STOCKMANAGER_REUSED ]
then
  echo "Checking for existing stockmanager repo"
  # do we already have one 

  OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
  OCIR_STOCKMANAGER_OCID=`oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME --all | jq -j '.data.items[0].id' `

  if [ $OCIR_STOCKMANAGER_OCID = 'null' ]
  then
  # No existing repo for stock manager
    echo "Creating OCIR repo named $OCIR_STOCKMANAGER_NAME for the stock manager in your tenancy in compartment  $COMPARTMENT_NAME"
    OCIR_STOCKMANAGER_OCID=`oci artifacts container repository create --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME --is-immutable false --is-public true --wait-for-state AVAILABLE | jq -j '.data.id'`
    echo "OCIR_STOCKMANAGER_OCID=$OCIR_STOCKMANAGER_OCID" >> $SETTINGS 
    echo "OCIR_STOCKMANAGER_REUSED=false" >> $SETTINGS
    # remove any existing location info and save the new one
    bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
    echo "OCIR_STOCKMANAGER_LOCATION=$OCIR_STOCKMANAGER_LOCATION" >> $SETTINGS
  else
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, reuse repo called $OCIR_STOCKMANAGER_NAME in compartment $COMPARTMENT_NAME for stockmanager defaulting to $REPLY"
    else
      read -p "There is an existing repo called $OCIR_STOCKMANAGER_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it (y/n) ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping script, the repo has not been reused, you need to re-run this script before doing any container image pushes"
      echo "docker has not been logged in"
      exit 1
    else     
      echo "OK, going to use reuse existing container repo called $OCIR_BASE_NAME in compartment $COMPARTMENT_NAME"
      echo "OCIR_STOCKMANAGER_OCID=$OCIR_STOCKMANAGER_OCID" >> $SETTINGS 
      echo "OCIR_STOCKMANAGER_REUSED=true" >> $SETTINGS
      # remove any existing location info and save the new one
      bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
      echo "OCIR_STOCKMANAGER_LOCATION=$OCIR_STOCKMANAGER_LOCATION" >> $SETTINGS
    fi
  fi
else
  echo "OCI Repo for stock manager has already been setup by this script, you can remove it and other repos using the ocir-delete.sh script, that will also remove any existing images"
fi

# now create the logger
if [ -z $OCIR_LOGGER_REUSED ]
then
  echo "Checking for existing logger repo"
  # do we already have one 

  OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
  OCIR_LOGGER_OCID=`oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_LOGGER_NAME --all | jq -j '.data.items[0].id' `

  if [ $OCIR_LOGGER_OCID = 'null' ]
  then
  # No existing repo for logger
    echo "Creating OCIR repo named $OCIR_LOGGER_NAME for the logger in your tenancy in compartment  $COMPARTMENT_NAME"
    OCIR_LOGGER_OCID=`oci artifacts container repository create --compartment-id $COMPARTMENT_OCID --display-name $OCIR_LOGGER_NAME --is-immutable false --is-public true --wait-for-state AVAILABLE | jq -j '.data.id'`
    echo "OCIR_LOGGER_OCID=$OCIR_LOGGER_OCID" >> $SETTINGS 
    echo "OCIR_LOGGER_REUSED=false" >> $SETTINGS
    # remove any existing location info and save the new one
    bash ./delete-from-saved-settings.sh OCIR_LOGGER_LOCATION
    echo "OCIR_LOGGER_LOCATION=$OCIR_LOGGER_LOCATION" >> $SETTINGS
  else
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, reuse repo called $OCIR_LOGGER_NAME in compartment $COMPARTMENT_NAME for logger defaulting to $REPLY"
    else
      read -p "There is an existing repo called $OCIR_LOGGER_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it for the logger (y/n) ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping script, the logger repo has not been reused, you need to re-run this script before doing any container image pushes"
      echo "docker has not been logged in for the logger repo"
      exit 1
    else     
      echo "OK, for logger going to use reuse existing container repo called $OCIR_LOGGER_NAME in compartment $COMPARTMENT_NAME"
      echo "OCIR_LOGGER_OCID=$OCIR_LOGGER_OCID" >> $SETTINGS 
      echo "OCIR_LOGGER_REUSED=true" >> $SETTINGS
      # remove any existing location info and save the new one
      bash ./delete-from-saved-settings.sh OCIR_LOGGER_LOCATION
      echo "OCIR_LOGGER_LOCATION=$OCIR_LOGGER_LOCATION" >> $SETTINGS
    fi
  fi
else
  echo "OCI Repo for logger has already been setup by this script, you can remove it and other repos using the ocir-delete.sh script, that will also remove any existing images"
fi


# now create the storefront
if [ -z $OCIR_STOREFRONT_REUSED ]
then
  echo "Checking for existing storefront repo"
  # do we already have one 

  OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront
  OCIR_STOREFRONT_OCID=`oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME --all | jq -j '.data.items[0].id' `

  if [ $OCIR_STOREFRONT_OCID = 'null' ]
  then
  # No existing repo for storefront
    echo "Creating OCIR repo named $OCIR_STOREFRONT_NAME for the storefront in your tenancy in compartment  $COMPARTMENT_NAME"
    OCIR_STOREFRONT_OCID=`oci artifacts container repository create --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME --is-immutable false --is-public true --wait-for-state AVAILABLE | jq -j '.data.id'`
    echo "OCIR_STOREFRONT_OCID=$OCIR_STOREFRONT_OCID" >> $SETTINGS 
    echo "OCIR_STOREFRONT_REUSED=false" >> $SETTINGS
    # remove any existing location info and save the new one
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION
    echo "OCIR_STOREFRONT_LOCATION=$OCIR_STOREFRONT_LOCATION" >> $SETTINGS
  else
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, reuse repo called $OCIR_STOREFRONT_NAME in compartment $COMPARTMENT_NAME for storefront defaulting to $REPLY"
    else
      read -p "There is an existing repo called $OCIR_STOREFRONT_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it for the storefront (y/n) ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping script, the storefront repo has not been reused, you need to re-run this script before doing any container image pushes"
      echo "docker has not been logged in for the stockmanager repo"
      exit 1
    else     
      echo "OK, for storefront going to use reuse existing container repo called $OCIR_STOREFRONT_NAME in compartment $COMPARTMENT_NAME"
      echo "OCIR_STOREFRONT_OCID=$OCIR_STOREFRONT_OCID" >> $SETTINGS 
      echo "OCIR_STOREFRONT_REUSED=true" >> $SETTINGS
      # remove any existing location info and save the new one
      bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION
      echo "OCIR_STOREFRONT_LOCATION=$OCIR_STOREFRONT_LOCATION" >> $SETTINGS
    fi
  fi
else
  echo "OCI Repo for storefront has already been setup by this script, you can remove it and other repos using the ocir-delete.sh script, that will also remove any existing images"
fi

SAVED_DIR=`pwd`
cd docker

FINAL_RESP=0
bash ./docker-login.sh $OCIR_STOCKMANAGER_LOCATION
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "docker login to $OCIR_STOCKMANAGER_LOCATION returned error $RESP"
  FINAL_RESP=$RESP
fi
bash ./docker-login.sh $OCIR_LOGGER_LOCATION
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "docker login to $OCIR_LOGGER_LOCATION returned error $RESP"
  FINAL_RESP=$RESP
fi
bash ./docker-login.sh $OCIR_STOREFRONT_LOCATION
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "docker login to $OCIR_STOREFRONT_LOCATION returned error $RESP"
  FINAL_RESP=$RESP
fi
if [ "$FINAL_RESP" -ne 0 ]
then
  echo "Error in docker logins, stopping"
  exit $FINAL_RESP
fi
