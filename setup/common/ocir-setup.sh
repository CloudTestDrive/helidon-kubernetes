#!/bin/bash -f


export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot continue
    exit 10
fi

if [ -z $USER_INITIALS ]
then
  echo Your initials have not been set, you need to run the initials-setup.sh script before you can run this script
  exit 1
fi

if [ -z $USER_OCID ]
then
  echo Your user OCID has not been set, you need to run the user-identity-setup.sh script before you can run this script
  exit 1
fi

if [ -z $OCIR_REUSED ]
then
  echo Creating new OCIR repo
else
  echo OCI Repo has already been setup by this script, you can remove it using the ocir-delete.sh script, that will also remove any existing images
  exit 1
fi


echo Determining settings

OCI_REGION_KEY=`oci iam region list --all | jq -e  ".data[]| select (.name == \"$OCI_REGION\")" | jq -j '.key' | tr [:upper:] [:lower:]`

OCIR_LOCATION=$OCI_REGION_KEY.ocir.io

OCI_USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`

OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

OCIR_NAME="$USER_INITIALS"_repo

read -p "Do you want to use $OCIR_NAME as the name of your repo ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the name of the container image repo to use, it must be a single word or multiple wordes separated by underscore , e.g. tg_repo"
  read OCIR_NAME
  if [ -z "$OCIR_NAME" ]
  then
    echo "You do actually need to enter the new name for the container image repo, exiting"
    exit 1
  fi
else     
  echo "OK, going to use $OCIR_NAME as the container image repo name"
fi

if [ -z $AUTH_TOKEN ]
then
  echo There is no saved auth token which is needed to log in to docker
  read -p "Please enter a valid auth token for your account" AUTH_TOKEN
  if [ -z $AUTH_TOKEN ]
  then
    echo You did not enter an auth token, this script cannot proceed without that
    echo Script stopping
  fi
else
  echo Using the saved auth token for the docker login
fi

COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`
  
# do we already have one 
OCIR_OCID=`oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_NAME --all | jq -j '.data.items[0].id'`

if [ -z $OCIR_OCID ]
then
  # No existing repo
  echo Creating OCIR repo named $OCIR_NAME in your tenancy in compartment  $COMPARTMENT_NAME
  OCIR_OCID=`oci artifacts container repository create --compartment-id $COMPARTMENT_OCID --display-name $OCIR_NAME --is-immutable false --is-public true --wait-for-state AVAILABLE | jq -j '.data.id'`
  echo OCIR_OCID=$OCIR_OCID >> $SETTINGS 
  echo OCIR_LOCATION=$OCIR_LOCATION >> $SETTINGS
  echo OCIR_REUSED=false >> $SETTINGS
else
  read -p "There is an existing repo called $OCIR_NAME in compartment $COMPARTMENT_NAME, do you want to re-use it ?" REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo OK, stopping script, the repo has not been used, you need to re-run this script before doing any container image pushes
    echo docker has not been logged in
  else     
    echo "OK, going to use reuse existing container repo called $OCIR_NAME in compartment $COMPARTMENT_NAME"
    echo OCIR_OCID=$OCIR_OCID >> $SETTINGS 
    echo OCIR_LOCATION=$OCIR_LOCATION >> $SETTINGS
    echo OCIR_REUSED=true >> $SETTINGS
  fi
fi


echo About to docker login to $OCIR_LOCATION and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token ads the password

docker login $OCIR_LOCATION --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password=$AUTH_TOKEN
