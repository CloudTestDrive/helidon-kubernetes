#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Settings file $SETTINGS located"
  else 
    echo "No settings file cannot continue"
    exit 10
fi

SERVICES_READY=false
until [ "$SERVICES_READY" = "true" ] 
do
  echo -n "Testing at " 
  date +'%H:%M:%S'
  SERVICES_READY=true
  # remove any previous values that may have been set
  for varName in "$@"
  do
    unset "$varName"
  done
  # get the latest settings
  source $SETTINGS
  for varName in "$@"
  do
    echo -n "Testing for $varName - "
    if [ -z "${!varName}" ]
    then
      echo "Not present"
      CORE_SERVICES_READY=false
    else
      echo "Found it"
    fi
  done
  
  if [ "$SERVICES_READY" = "true" ]
  then
    echo "Required services are indicating ready"
  else
    echo "Waiting for the next test"
    sleep 10
  fi
done