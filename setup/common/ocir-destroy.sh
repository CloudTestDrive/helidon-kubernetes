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

echo "OCIR_BASE_NAME=$OCIR_BASE_NAME" >> $SETTINGS
if [ -z "$OCIR_BASE_NAME" ]
then
  echo "Cannot locate the OCIR_BASE_NAME, unable to proceed"
  exit 5 ;
fi
# create the repos
OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront
cd ocir
bash ./ocir-destroy.sh $OCIR_STOCKMANAGER_NAME true false
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem destroying the stockmanager repo, cannot continue"
  exit $RESP
fi
bash ./ocir-destroy.sh $OCIR_STOREFRONT_NAME true false
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem destroying the stockmanager repo, cannot continue"
  exit $RESP
fi
bash ./ocir-destroy.sh $OCIR_LOGGER_NAME true false
RESP=$?
if [ "$RESP" != 0 ] 
then
  echo "Problem destroying the logger repo, cannot continue"
  exit $RESP
fi
cd ..


bash ./delete-from-saved-settings.sh OCIR_STOCKMANAGER_LOCATION
bash ./delete-from-saved-settings.sh OCIR_LOGGER_LOCATION
bash ./delete-from-saved-settings.sh OCIR_STOREFRONT_LOCATION
bash ./delete-from-saved-settings.sh OCIR_BASE_NAME

echo "You are still logged into docker for OCIR services on the stockmanager in $OCIR_STOCKMANAGER_LOCATION"
echo "If you with to logout from that execute the command"
echo "docker logout $OCIR_STOCKMANAGER_LOCATION"

echo "You are still logged into docker for OCIR services on the logger in $OCIR_LOGGER_LOCATION"
echo "If you with to logout from that execute the command"
echo "docker logout $OCIR_LOGGER_LOCATION"

echo "You are still logged into docker for OCIR services on the storefront in $OCIR_STOREFRONT_LOCATION"
echo "If you with to logout from that execute the command"
echo "docker logout $OCIR_STOREFRONT_LOCATION"

echo "If both locations are the same you only need to do this once"