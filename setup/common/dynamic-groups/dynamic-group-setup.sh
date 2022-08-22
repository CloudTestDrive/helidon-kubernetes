#!/bin/bash -f

SCRIPT_NAME=`basename $0`

if [ $# -lt 3 ]
then
  echo "$SCRIPT_NAME requires three arguments:"
  echo "the rule of the dynamic group to create"
  echo "the resource type of the dynamic group e.g. devopsbuildpipeline"
  echo "the description of the dynamic group (which needs to be quoted)"
  exit 1
fi

GROUP_NAME=$1
GROUP_RULE=$2
GROUP_DESCRIPTION=$3
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_OCID
GROUP_REUSED_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_REUSED

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

# look for reuse info on the group, if so it's already there

if [ -z "${!GROUP_REUSED_NAME}" ]
then
  echo "No reuse info for dynamic group $GROUP_NAME"
else
  echo "This script has already setup the dynamic group $GROUP_NAME"
  exit 0
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
# see if we can find the existing group
# it must be active to be usable
GROUP_OCID=`oci iam dynamic-group list --name $GROUP_NAME  --lifecycle-state ACTIVE --region $OCI_HOME_REGION | jq -r '.data[0].id'`

echo "Checking for existing dynamic group named $GROUP_NAME"
if [ -z "$GROUP_OCID" ]
then
  echo "No existing dynamic group found, creating"  
  GROUP_OCID=`oci iam dynamic-group create --region $OCI_HOME_REGION --name "$GROUP_NAME" --description "$GROUP_DESCRIPTION"  --matching-rule "$GROUP_RULE" --wait-for-state ACTIVE | jq -r '.data.id'`
  if [ -z "$GROUP_OCID" ]
  then
    GROUP_OCID=null
  fi
  if [ "$GROUP_OCID" = "null" ]
  then
    echo "Unable to create dynamic group $GROUP_NAME, cannot continue"
    exit 4
  fi
  echo "Waiting for dynamic group to propogate"
  DG_FOUND=false
  for i in `seq 1 10`
  do
    echo "Propogate test $i for dynamic group $GROUP_NAME"
    COUNT=`oci iam dynamic-group list --name $GROUP_NAME --lifecycle-state ACTIVE | jq -r 'length'`
    if [ "$COUNT" = "1" ]
    then
      echo "Dynamic group has propogated"
      DG_FOUND=true
      break ;
    fi
    sleep 10
  done
  if [ "$DG_FOUND" = "true" ]
  then
    echo $GROUP_OCID_NAME=$GROUP_OCID >> $SETTINGS
    echo $GROUP_REUSED_NAME=false >> $SETTINGS
    exit 0
  else
    echo "Dynamic group has not propogated in time, stopping"
    exit 1
  fi
else
  echo "Group named $GROUP_NAME already exists, please manually add the following rule to it " 
  echo $GROUP_RULE
  echo $GROUP_OCID_NAME=$GROUP_OCID >> $SETTINGS
  echo $GROUP_REUSED_NAME=true >> $SETTINGS
  exit 1
fi