#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 2 ]
then
  echo "$SCRIPT_NAME requires two arguments:"
  echo "the name of the dynamic group to create"
  echo "the description of the dynamic group (which needs to be quoted)"
  echo "optionall a 3rd argument of the OCID of the compatment containing matching instance if nto COMPARTMENT_OCID will be used form the settings if present"
  exit 1
fi

GROUP_NAME=$1
GROUP_DESCRIPTION=$2

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ $# -eq 3 ]
then
  COMPARTMENT_OCID=$3
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set or provided as a command option, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


GROUP_RULE="Any {instance.compartment.id = '$COMPARTMENT_OCID'}"

bash ./dynamic-group-setup.sh "$GROUP_NAME" "$GROUP_DESCRIPTION" "$GROUP_RULE"