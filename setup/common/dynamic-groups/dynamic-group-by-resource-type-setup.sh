#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 3 ]
then
  echo "$SCRIPT_NAME requires three arguments:"
  echo "the name of the dynamic group to create"
  echo "the resource type of the dynamic group e.g. devopsbuildpipeline"
  echo "the description of the dynamic group (which needs to be quoted)"
  exit 1
fi

GROUP_NAME=$1
GROUP_RESOURCE_TYPE=$2
GROUP_DESCRIPTION=$3

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


GROUP_RULE="ALL {resource.type = '$GROUP_RESOURCE_TYPE', resource.compartment.id = '$COMPARTMENT_OCID'}"

bash ./dynamic-group-setup.sh "$GROUP_NAME" "$GROUP_RULE" "$GROUP_DESCRIPTION"