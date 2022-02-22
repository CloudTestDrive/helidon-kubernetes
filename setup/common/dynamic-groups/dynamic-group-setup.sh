#!/bin/bash -f

if [ $# -lt 2 ]
then
  echo "The user group setup script requires three arguments:"
  echo "the name of the dynamic group to create"
  echo "the resource typoe of the dynamic group e.g. devopsbuildpipeline"
  echo "the description of the dynamic group (which needs to be quoted)"
  exit 1
fi

GROUP_NAME=$1
GROUP_RESOURCE_TYPE=$2
GROUP_DESCRIPTION=$3
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=GROUP_"$GROUP_NAME_CAPS"_OCID
GROUP_REUSED_NAME=GROUP_"$GROUP_NAME_CAPS"_REUSED

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 2
fi

# look for reuse info on the group, if so it's already there

if [ -z "${!GROUP_REUSED_NAME}" ]
then
  echo "No reuse info for dynamic group $GROUP_NAME"
else
  echo "This script has already setup the dynamic group $GROUP_NAME"
  exit 0
fi

# see if we can find the existing group

GROUP_OCID=`oci iam dynamic-group list --name $GROUP_NAME | jq -r '.data[0].id'`

GROUP_RULE="ALL {resource.type = '$GROUP_RESOURCE_TYPE', resource.compartment.id = '$COMPARTMENT_OCID'}"

echo "Checking for existing dynamic group named $GROUP_NAME"
if [ -z "$GROUP_OCID" ]
then
  echo "No existing dynamic group found, creating"
  GROUP_RULE="ALL {resource.type = '$GROUP_RESOURCE_TYPE', resource.compartment.id = '$COMPARTMENT_OCID'}"
  GROUP_OCID=`oci iam create dynamic-group --name "$GROUP_NAME" --description "$GROUP_DESCRIPTION"  --matching-rule "$GROUP_RULE" --wait-for-state ACTIVE | jq -r '.data.id'`
  echo $GROUP_OCID_NAME=$GROUP_OCID >> $SETTINGS
  echo $GROUP_REUSED_NAME=false >> $SETTINGS
  exit 0
else
  echo "Group named $GROUP_NAME already exists, please manually add the following rule to it " 
  echo $GROUP_RULE
  echo $GROUP_OCID_NAME=$GROUP_OCID >> $SETTINGS
  echo $GROUP_REUSED_NAME=true >> $SETTINGS
fi