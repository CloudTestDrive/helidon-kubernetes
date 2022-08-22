#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 2 ]
then
  echo "$SCRIPT_NAME requires two arguments, the name of the group and the description (which needs to be quoted)"
  exit 1
fi

GROUP_NAME=$1
GROUP_DESCRIPTION=$2
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=GROUP_"$GROUP_NAME_CAPS"_OCID
GROUP_REUSED_NAME=GROUP_"$GROUP_NAME_CAPS"_REUSED

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

# look for reuse info on the group, if so it's already there

if [ -z "${!GROUP_REUSED_NAME}" ]
then
  echo "This script has already setup the group $GROUP_NAME it will be reused"
  exit 0
fi

# see if we can find the existing group

GROUP_OCID=`oci iam group list --name $GROUP_NAME | jq -r '.data[0].id`

echo "Checking for existing group named $GROUP_NAME"
if [ -z "$GROUP_OCID" ]
then
  echo "No existing group found, creating"
  GROUP_OCID=`oci iam create group --name "$GROUP_NAME" --description "$GROUP_DESCRIPTION" | jq -r '.data.id'`
  if [ -z "$GROUP_OCID" ]
  then
    echo "Problem setting up group $GROUP_NAME, cannot continue"
    exit 12
  fi
  echo "$GROUP_OCID_NAME=$GROUP_OCID" >> $SETTINGS
  echo "$GROUP_REUSED_NAME=false" >> $SETTINGS
else
  echo "Group named $GROUP_NAME already exists, reusing it"  
  echo "$GROUP_OCID_NAME=$GROUP_OCID" >> $SETTINGS
  echo "$GROUP_REUSED_NAME=true" >> $SETTINGS
fi
  