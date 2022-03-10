#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have provided the correct value in the first param"
  exit 99
fi

RESOURCES_AVAILABLE=true

if [ -z $VAULT_OCID ]
then
  echo "No existing vault information, checking for resource availabilty"
  bash ../common/resources/resource-minimum-check-region-compartment.sh $COMPARTMENT_OCID kms virtual-vault-count 1
  AVAIL_VAULTS=$?

  if [ $AVAIL_VAULTS -eq 0 ]
  then
    echo "You have enough vaults  available in compartment $COMPARTMENT_NAME to run this lab"
  else
    echo "You do not have enpugh vaults available in compartment $COMPARTMENT_NAME to run this lab, please delete some"
    RESOURCES_AVAILABLE=false
  fi
else
  echo "This script has already configured vault no need to check it's resource availability"
fi

# how many dynamic groups are needed ?
DYNAMIC_GROUPS_MAX=50
DYNAMIC_GROUPS_NEEDED=3
DYNAMIC_GROUPS_COUNT=`oci iam dynamic-group list --compartment-id $OCI_TENANCY --all | jq -r '.data | length'`

if [ -z "$DYNAMIC_GROUPS_COUNT" ]
then
  DYNAMIC_GROUPS_COUNT=$DYNAMIC_GROUPS_MAX
fi

let DYNAMIC_GROUPS_AVAIL=$DYNAMIC_GROUPS_MAX=-$DYNAMIC_GROUPS_COUNT

if [ "$DYNAMIC_GROUPS_AVAIL" -lt "$DYNAMIC_GROUPS_NEEDED" ]
then
  echo "You need $DYNAMIC_GROUPS_NEEDED in your tenacy to run this lab, unfortunately you only have $DYNAMIC_GROUPS_AVAIL"
  RESOURCES_AVAILABLE=false
fi

if [ $RESOURCES_AVAILABLE ]
then
  echo "Congratulations, you have either got an existing vault created from other labs, or"
  echo "if not based on current resource availability (which if other people are using this tenancy"
  echo "may of course change before the OKE cluster is created) there are sufficient resources to do this lab"
  exit 0
else
  echo "You do not have the resources available to run this lab."
  echo "Depending on the message above you will need to delete some dynamic groups or vaults to be able to continue"
  exit 50
fi