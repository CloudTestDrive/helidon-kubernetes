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

echo "OCIR_BASE_NAME=$OCIR_BASE_NAME" >> $SETTINGS

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

# create the repos
OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront
PUBLIC=true
IMMUTABLE=false
cd ocir
bash ./ocir-setup.sh $OCIR_STOCKMANAGER_NAME $PUBLIC $IMMUTABLE
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem creating the stockmanager repo, cannot continue"
  exit $RESP
fi
bash ./ocir-setup.sh $OCIR_STOREFRONT_NAME $PUBLIC $IMMUTABLE
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem creating the stockmanager repo, cannot continue"
  exit $RESP
fi
bash ./ocir-setup.sh $OCIR_LOGGER_NAME $PUBLIC $IMMUTABLE
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem creating the logger repo, cannot continue"
  exit $RESP
fi
cd ..

# remove any old location info
bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
bash ./delete-from-saved-settings.sh OCIR_LOGGER_LOCATION
bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION

# save the image locations so the build processes know where to put things
echo "OCIR_STOCKMANAGER_LOCATION=$OCIR_STOCKMANAGER_LOCATION" >> $SETTINGS
echo "OCIR_LOGGER_LOCATION=$OCIR_LOGGER_LOCATION" >> $SETTINGS
echo "OCIR_STOREFRONT_LOCATION=$OCIR_STOREFRONT_LOCATION" >> $SETTINGS
# do the docker login, in theory these might be in different locaitons in the future, even though for now they are not
# so we'll do a login for each location as future proofing
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

echo "About to docker login for logger repo to $OCIR_LOGGER_LOCATION and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token as the password"
echo "Please ignore warnings about insecure password storage"
echo "It can take a short while for a new auth token to be propogated to the OCIR service, so if the docker login fails do not be alarmed the script will retry after a short delay."
for i in  `seq 1 $MAX_LOGIN_ATTEMPTS` 
do
  echo -n $AUTH_TOKEN | docker login $OCIR_LOGGER_LOCATION --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password-stdin
  RESP=$?
  echo "Docker Login resp is $RESP"
  if [ $RESP = 0 ]
  then
    echo "docker login to $OCIR_LOGGER_LOCATION suceeded on attempt $i, continuing"
    break ;
  else
    echo "docker login to $OCIR_LOGGER_LOCATION failed on attempt $i, retrying after pause"
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

