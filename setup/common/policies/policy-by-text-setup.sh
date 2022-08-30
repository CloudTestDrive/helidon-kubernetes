#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 3 ]
then
  echo "$SCRIPT_NAME requires three arguments:"
  echo "the name of the policy to create"
  echo "the policy text - this should be quoted as it's mutiple words"
  echo "the description of the dynamic group (which needs to be quoted if it's multiple words)"
  exit 1
fi

POLICY_NAME=$1
POLICY_RULE=$2
POLICY_DESCRIPTION=$3
POLICY_NAME_CAPS=`bash ../settings/to-valid-name.sh $POLICY_NAME`
POLICY_OCID_NAME=POLICY_"$POLICY_NAME_CAPS"_OCID
POLICY_REUSED_NAME=POLICY_"$POLICY_NAME_CAPS"_REUSED

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

if [ -z $COMPARTMENT_OCID ]
then
  echo "$SCRIPT_NAME Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


# look for reuse info on the group, if so it's already there

if [ -z "${!POLICY_REUSED_NAME}" ]
then
  echo "No reuse info for policy $POLICY_NAME"
else
  echo "$SCRIPT_NAME  has already setup the policy $POLICY_NAME"
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
# it needs to be active
POLICY_OCID=`oci iam policy list --name $POLICY_NAME --compartment-id $COMPARTMENT_PARENT_OCID  --lifecycle-state ACTIVE | jq -r '.data[0].id'`

echo "Checking for existing policy named $POLICY_NAME in compartment $COMPARTMENT_PARENT_NAME"
if [ -z "$POLICY_OCID" ]
then
  echo "No existing policy found with name $POLICY_NAME in compartment $COMPARTMENT_PARENT_NAME, creating policy with rule $POLICY_RULE"
  echo "Getting home region"
  OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
  OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
  echo "No existing policy found, creating"
  POLICY_OCID=`oci iam policy create --region $OCI_HOME_REGION --name "$POLICY_NAME" --description "$POLICY_DESCRIPTION"  --statements "$POLICY_RULE" --compartment-id $COMPARTMENT_PARENT_OCID --wait-for-state ACTIVE | jq -r '.data.id'`
  echo "Waiting for policy to propogate"
  POLICY_FOUND=false
  for i in `seq 1 10`
  do
    echo "Propogate test $i for policy $POLICY_NAME"
    COUNT=`oci iam policy list --name $POLICY_NAME --compartment-id $COMPARTMENT_PARENT_OCID  --lifecycle-state ACTIVE | jq -r 'length'`
    if [ "$COUNT" = "1" ]
    then
      echo "Policy has propogated"
      POLICY_FOUND=true
      break ;
    fi
    sleep 10
  done
  if [ "$POLICY_FOUND" = "true" ]
  then
    echo "$POLICY_OCID_NAME=$POLICY_OCID" >> $SETTINGS
    echo "$POLICY_REUSED_NAME=false" >> $SETTINGS
    exit 0
  else
    echo "Policy has not propogated in time, stopping"
    exit 1
  fi
else
  echo "Policy named $POLICY_NAME already exists, please manually add the following statement to it " 
  echo "$POLICY_RULE"
  echo "$POLICY_OCID_NAME=$POLICY_OCID" >> $SETTINGS
  echo "$POLICY_REUSED_NAME=true" >> $SETTINGS
  exit 0
fi