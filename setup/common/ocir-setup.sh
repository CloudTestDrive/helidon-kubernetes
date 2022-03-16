#!/bin/bash -f


export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

if [ -z $USER_OCID ]
then
  echo "Your user OCID has not been set, you need to run the user-identity-setup.sh script before you can run this script"
  exit 1
fi

echo "Determining settings"

OCI_REGION_KEY=`oci iam region list --all | jq -e  ".data[]| select (.name == \"$OCI_REGION\")" | jq -j '.key' | tr [:upper:] [:lower:]`

OCIR_STOCKMANAGER_LOCATION=$OCI_REGION_KEY.ocir.io
OCIR_STOREFRONT_LOCATION=$OCI_REGION_KEY.ocir.io

OCI_USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`

OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

OCIR_BASE_NAME="$USER_INITIALS"_labs_base_repo

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, use $OCIR_BASE_NAME as the base for naming your repo defaulting to $REPLY"
else
  read -p "Do you want to use $OCIR_BASE_NAME as the base for naming your repo ? " REPLY
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
      read -p "There is an existing repo called $OCIR_STOCKMANAGER_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping script, the repo has not been used, you need to re-run this script before doing any container image pushes"
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
      read -p "There is an existing repo called $OCIR_STOREFRONT_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it for the storefront ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping script, the storefront repo has not been configured, you need to re-run this script before doing any container image pushes"
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


MAX_LOGIN_ATTEMPTS=12
DOCKER_LOGIN_FAILED_SLEEP_TIME=10
echo "About to docker login for stockmanager repo to $OCIR_STOCKMANAGER_LOCATION and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token as the password"
echo "Please ignore warnings about insecure password storage"
echo "It can take a short while for a new auth token to be propogated to the OCIR service, so if the docker login fails do not be alarmed the script will retry after a short delay."
for i in  `seq 1 $MAX_LOGIN_ATTEMPTS` 
do
  echo -n $AUTH_TOKEN | docker login $OCIR_STOCKMANAGER_LOCATION --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password-stdin
  RESP=$?
  echo "Docker Login resp is $RESP"
  if [ $RESP = 0 ]
  then
    echo "docker login to $OCIR_STOCKMANAGER_LOCATION suceeded on attempt $i, continuing"
    break ;
  else
    echo "docker login to $OCIR_STOCKMANAGER_LOCATION failed on attempt $i, retrying after pause"
    sleep $DOCKER_LOGIN_FAILED_SLEEP_TIME
  fi
  if [ $i -eq $MAX_LOGIN_ATTEMPTS ]
  then
    echo "Unable to complete docker login after 12 attempts, cannot continue"
    exit 10
  fi
done

echo "About to docker login for storefront repo to $OCIR_STOREFRONT_LOCATION and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token as the password"
echo "Please ignore warnings about insecure password storage"
echo "It can take a short while for a new auth token to be propogated to the OCIR service, so if the docker login fails do not be alarmed the script will retry after a short delay."
for i in  `seq 1 $MAX_LOGIN_ATTEMPTS` 
do
  echo -n $AUTH_TOKEN | docker login $OCIR_STOREFRONT_LOCATION --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password-stdin
  RESP=$?
  echo "Docker Login resp is $RESP"
  if [ $RESP = 0 ]
  then
    echo "docker login to $OCIR_STOCKMANAGER_LOCATION suceeded on attempt $i, continuing"
    break ;
  else
    echo "docker login to $OCIR_STOCKMANAGER_LOCATION failed on attempt $i, retrying after pause"
    sleep $DOCKER_LOGIN_FAILED_SLEEP_TIME
  fi
  if [ $i -eq $MAX_LOGIN_ATTEMPTS ]
  then
    echo "Unable to complete docker login after 12 attempts, cannot continue"
    exit 10
  fi
done

