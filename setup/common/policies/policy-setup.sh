#!/bin/bash -f

if [ $# -lt 4 ]
then
  echo "The policy setup script requires four arguments:"
  echo "the name of the policy to create"
  echo "the type of policy e.g. group or dynamic-group"
  echo "The subject of the polidy c.c. tgDevopsGroup"
  echo "the description of the dynamic group (which needs to be quoted if it's multiple words)"
  exit 1
fi

POLICY_NAME=$1
POLICY_TYPE=$2
POLICY_SUBJECT=$3
POLICY_DESCRIPTION=$4
POLICY_NAME_CAPS=`bash ../settings/to-valid-name.sh $POLICY_NAME`
POLICY_OCID_NAME=POLICY_"$POLICY_NAME_CAPS"_OCID
POLICY_REUSED_NAME=POLICY_"$POLICY_NAME_CAPS"_REUSED

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


# look for reuse info on the group, if so it's already there

if [ -z "${!POLICY_REUSED_NAME}" ]
then
  echo "No reuse info for policy $POLICY_NAME"
else
  echo "This script has already setup the policy $POLICY_NAME"
  exit 0
fi

# Get the comparment name
COMPARTMENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data.name'`
# get the compartment parent
COMPARTMENT_PARENT_OCID=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data."compartment-id"'`

# work out the parent's name
if [ $OCI_TENANCY = $COMPARTMENT_PARENT_OCID ]
then
   COMPARTMENT_PARENT_NAME="Tenancy root"
else
   COMPARTMENT_PARENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_PARENT_OCID | jq -r '.data.name'`
fi

# see if we can find the existing group

POLICY_OCID=`oci iam policy list --name $POLICY_NAME --compartment-id $COMPARTMENT_PARENT_OCID | jq -r '.data[0].id'`

POLICY_RULE="[ \"ALLOW $POLICY_TYPE $POLICY_SUBJECT to manage all-resources in compartment $COMPARTMENT_NAME \"]" 

echo "Checking for existing policy named $POLICY_NAME in compartment $COMPARTMENT_PARENT_NAME"
if [ -z "$POLICY_OCID" ]
then
  echo "No existing policy found, creating"
  POLICY_OCID=`oci iam policy create --name "$POLICY_NAME" --description "$POLICY_DESCRIPTION"  --statements "$POLICY_RULE" --compartment-id $COMPARTMENT_PARENT_OCID --wait-for-state ACTIVE | jq -r '.data.id'`
  echo "$POLICY_OCID_NAME=$POLICY_OCID" >> $SETTINGS
  echo "$POLICY_REUSED_NAME=false" >> $SETTINGS
  exit 0
else
  echo "Policy named $POLICY_NAME already exists, please manually add the following statement to it " 
  echo "$POLICY_RULE"
  echo "$POLICY_OCID_NAME=$POLICY_OCID" >> $SETTINGS
  echo "$POLICY_REUSED_NAME=true" >> $SETTINGS
  exit 1
fi