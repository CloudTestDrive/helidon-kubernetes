#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Settings file $SETTINGS located"
  else 
    echo "No settings file cannot continue"
    exit 10
fi

CORE_SERVICES_READY=false
until [ "$CORE_SERVICES_READY" = "true" ] 
do
  source $SETTINGS
  CORE_SERVICES_READY=true
  echo -n "Testing for ATP OCID - "
  if [ -z "$ATPDB_OCID" ]
  then
    echo "Not present"
    CORE_SERVICES_READY=false
  else
    echo "Found it"
  fi
  
  echo -n "Testing for OKE OCID - "
  if [ -z "$OKE_OCID" ]
  then
    echo "Not present"
    CORE_SERVICES_READY=false
  else
    echo "Found it"
  fi
  
  echo -n "Testing for Image availability - "
  if [ -z "$IMAGES_READY" ]
  then
    echo "Not ready"
    CORE_SERVICES_READY=false
  else
    echo "Found them"
  fi
  
  if [ "$CORE_SERVICES_READY" = "true" ]
  then
    echo "Required core setup scripts complete, continuing"
  else
    echo "Waiting for the next test"
    sleep 10
  fi
done