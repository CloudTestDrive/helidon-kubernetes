#!/bin/bash
display_usage () {
    echo "Missing arguments, you must provide these arguments in order :"
    echo "Operation to be performed this is one of set or reset"
    echo "Location of the template yaml file (withouth the .yaml)"
    echo "If the operation is set then you must also provide"
    echo "Name of the OCIR host e.g. fra.ocir.io"
    echo "Name of the object storage namespace - this is a set of random letters and numbers usually"
    echo "Name of the OCIR repository for the namespace e.g. tg_base_lab_repo/storefront"
}
if [ $# -lt 2 ]
then
    display_usage
    exit 1
fi

CMD=$1
TEMPLATE=$2
TEMPLATE_DIR=`dirname $TEMPLATE`
TEMPLATE_BASE=`basename $TEMPLATE -template.yaml`
DEPLOYMENT_YAML=$TEMPLATE_DIR/$TEMPLATE_BASE.yaml
if [ $CMD = set ]
then
  echo Configuring from $TEMPLATE
elif [ $CMD = reset ]
    echo Resetting to $TEMPLATE
else
    display_usage
    exit 2
fi


if [ $CMD = set ]
then
  if [ $# -lt 5 ]
  then
    display_usage
    exit -1 
  fi 
  OCIR_LOCATION=$3
  OCIR_STORAGE_NAMESPACE=$4
  OCIR_REPO=$5
fi


if [ $CMD = set ]
then
  echo Configuring deployment $DEPLOYMENT_YAML with provided location details of Location $OCIR_LOCATION storage namespace $OCIR_STORAGE_NAMESPACE and repo $OCIR_REPO
  cp $TEMPLATE $DEPLOYMENT_YAML
  bash update-file.sh $DEPLOYMENT_YAML OCIR_LOCATION $OCIR_LOCATION
  bash update-file.sh $DEPLOYMENT_YAML OCIR_STORAGE_NAMESPACE $OCIR_STORAGE_NAMESPACE
  bash update-file.sh $DEPLOYMENT_YAML OCIR_REPO $OCIR_REPO ':'
  echo Completed setting location details for $DEPLOYMENT_YAML
elif [ $CMD = reset ]
then 
  echo Configuring deployment $1 removing $DEPLOYMENT_YAML
  rm $DEPLOYMENT_YAML
else
  echo Unknown operation $CMD, 1st argument must be either set or reset
fi