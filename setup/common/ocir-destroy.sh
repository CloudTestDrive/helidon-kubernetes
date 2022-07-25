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

if [ -z $OCIR_STOCKMANAGER_REUSED ]
then
  echo "No reuse information for OCIR stockmanager repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_STOCKMANAGER_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the stock manager that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_STOCKMANAGER_OCID --force
  fi
    echo "Removing storefront repo saved values from $SETTINGS"
    bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_OCID
    bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_REUSED
    bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
fi


if [ -z $OCIR_LOGGING_REUSED ]
then
  echo "No reuse information for OCIR stockmanager repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_LOGGING_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the logging that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_LOGGING_OCID --force
  fi
    echo "Removing logging repo saved values from $SETTINGS"
    bash ./delete-from-saved-settings.sh OCIR_LOGGING_OCID
    bash ./delete-from-saved-settings.sh OCIR_LOGGING_REUSED
    bash ./delete-from-saved-settings.sh OCIR_LOGGING_LOCATION
fi

if [ -z $OCIR_STOREFRONT_REUSED ]
then
  echo "No reuse information for OCIR storefront repo, cannot safely continue, you will have to destroy it manually"
else
  if [ $OCIR_STOREFRONT_REUSED = true ]
  then
    echo "You have been using an OCIR repo for the storefront that was not created by these scripts, you will need to destroy the repo by hand"
  else 
    echo "Destroying repo"
    oci artifacts container repository delete --repository-id $OCIR_STOREFRONT_OCID --force
  fi
    echo "Removing storefront repo saved values from $SETTINGS"
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_OCID
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_REUSED
    bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION
fi

echo "You are still logged into docker for OCIR services on the stockmanager in $OCIR_STOCKMANAGER_LOCATION"
echo "If you with to logout from that execute the command"
echo "docker logout $OCIR_STOCKMANAGER_LOCATION"

echo "You are still logged into docker for OCIR services on the storefront in $OCIR_STOREFRONT_LOCATION"
echo "If you with to logout from that execute the command"
echo "docker logout $OCIR_STOREFRONT_LOCATION"

echo "If both locations are the same you only need to do this once"