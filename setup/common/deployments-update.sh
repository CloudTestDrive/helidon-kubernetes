#!/bin/bash
if [ $# -lt 5 ]
  then
    echo "Missing arguments, you must provide these arguments in order :"
    echo "Operation to be performed this is one of set or reset"
    echo "Location of the deployment yaml file"
    echo "Name of the OCIR host e.g. fra.ocir.io"
    echo "Name of the object storage namespace - this is a set of random letters and numbers usually"
    echo "Name of the OCIR repository for the namespace e.g. tg_base_lab_repo/storefront"
    exit -1 
fi

CMD=$1
DEPLOYMENT_YAML=$2
OCIR_LOCATION=$3
OCIR_STORAGE_NAMESPACE=$4
OCIR_REPO=$5

if [ $CMD = set ]
then
  echo Configuring deployment $1 with provided location details
  bash update-file.sh $1 OCIR_LOCATION $OCIR_LOCATION
  bash update-file.sh $1 OCIR_STORAGE_NAMESPACE $OCIR_STORAGE_NAMESPACE
  bash update-file.sh $1 OCIR_REPO $OCIR_REPO
  echo Completed setting location details for $1
elif [ $CMD = reset ]
then
  echo Configuring deployment $1 removing provided location details
  bash update-file.sh $1 $OCIR_LOCATION OCIR_LOCATION
  bash update-file.sh $1 $OCIR_STORAGE_NAMESPACE OCIR_STORAGE_NAMESPACE
  bash update-file.sh $1 $OCIR_REPO OCIR_REPO
  echo Completed resetting location details for $1
  exit 0
else
  echo Unknown operation $CMD, 1st argument must be either set or reset
fi