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

if [ -z $OCIR_STOCKMANAGER_REUSED ]
then
  echo "$SCRIPT_NAME No reuse information for OCIR stockmanager repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_STOCKMANAGER_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the stock manager that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_STOCKMANAGER_OCID --force
  fi
  if [ -z "$OCIR_STOCKMANAGER_LOCATION" ]
  then
    echo "No OCIR info for stockmanager, cannot do a docker logout"
  else
  echo "Logging out of docker for stockmanager repo $OCIR_STOCKMANAGER_LOCATION"
    SAVED_DIR=`pwd`
    cd docker
    bash ./docker-logout.sh $OCIR_STOCKMANAGER_LOCATION
    cd $SAVED_DIR
  fi
  echo "Removing storefront repo saved values from $SETTINGS"
  bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_OCID
  bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_REUSED
  bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
fi


if [ -z $OCIR_LOGGER_REUSED ]
then
  echo "$SCRIPT_NAME No reuse information for OCIR logger repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_LOGGER_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the logger that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_LOGGER_OCID --force
  fi
  if [ -z "$OCIR_LOGGER_LOCATION" ]
  then
    echo "No OCIR info for logger, cannot do a docker logout"
  else
  echo "Logging out of docker for logger repo $OCIR_LOGGER_LOCATION"
    SAVED_DIR=`pwd`
    cd docker
    bash ./docker-logout.sh $OCIR_LOGGER_LOCATION
    cd $SAVED_DIR
  fi
  echo "Removing logger repo saved values from $SETTINGS"
  bash ./delete-from-saved-settings.sh OCIR_LOGGER_OCID
  bash ./delete-from-saved-settings.sh OCIR_LOGGER_REUSED
  bash ./delete-from-saved-settings.sh OCIR_LOGGER_LOCATION
fi

if [ -z $OCIR_STOREFRONT_REUSED ]
then
  echo "$SCRIPT_NAME No reuse information for OCIR storefront repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_STOREFRONT_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the storefront that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_STOREFRONT_OCID --force
  fi
  if [ -z "$OCIR_LOGGER_LOCATION" ]
  then
    echo "No OCIR info for stockmanager, cannot do a docker logout"
  else
  echo "Logging out of docker for storefront repo $OCIR_STOREFRONT_LOCATION"
    SAVED_DIR=`pwd`
    cd docker
    bash ./docker-logout.sh $OCIR_STOREFRONT_LOCATION
    cd $SAVED_DIR
  fi
    echo "Removing storefront repo saved values from $SETTINGS"
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_OCID
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_REUSED
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION
fi
