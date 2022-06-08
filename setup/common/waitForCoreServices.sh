#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

OKE_OCID_NAME=OKE_OCID_$CLUSTER_CONTEXT_NAME

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
  # remove any pre3vious values
  unset ATPDB_OCID $OKE_OCID_NAME IMAGES_READY
  echo -n "Testing at " 
  date +'%H:%M:%S'
  source $SETTINGS
  CORE_SERVICES_READY=true
  echo -n "Testing for ATPDB_OCID - "
  if [ -z "$ATPDB_OCID" ]
  then
    echo "Not present"
    CORE_SERVICES_READY=false
  else
    echo "Found it"
  fi
  
  OKE_OCID="${!OKE_OCID_NAME}"
  
  echo -n "Testing for $OKE_OCID_NAME "
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
    echo "Required core setup scripts complete"
  else
    echo "Waiting for the next test"
    sleep 10
  fi
done