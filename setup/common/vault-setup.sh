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

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


if [ -z $VAULT_REUSED ]
then
  echo "No reuse information for vault"
else
  echo "This script has already configured vault details, exiting"
  exit 3
fi

# check for resource availability

bash ./resources/resource-minimum-check-region-compartment.sh $COMPARTMENT_OCID kms virtual-vault-count 1

if [ $? = 0 ]
then
  echo "Vault resources ara available, continuing"
else
  echo "No vault resources available, cannot continue"
  exit 10
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS"
  exit 99
else
  echo "Operating in compartment $COMPARTMENT_NAME"
fi

VAULT_NAME="$USER_INITIALS"LabsVault

read -p "Do you want to use $VAULT_NAME as the name of the vault to create or re-use in $COMPARTMENT_NAME?" REPLY

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the name of the vault to create / re-use, it must be a single word, e.g. tgLabsVault"
  read VAULT_NAME
  if [ -z "$VAULT_NAME" ]
  then
    echo "You do actually need to enter the new name for the vault, exiting"
    exit 1
  fi
else     
  echo "OK, going to use $VAULT_NAME as the vault name"
fi

#allow for re-using an existing vault if specified
if [ -z $VAULT_OCID ]
  then
  # No existing VAULT_OCID so need to potentially create it
  echo "Checking for  vault $VAULT_NAME in compartment $COMPARTMENT_NAME"
  VAULT_PENDING_OCID=`oci kms management vault list --compartment-id $COMPARTMENT_OCID --all | jq -e ".data[] | select ((.\"lifecycle-state\"==\"PENDING_DELETION\") and (.\"display-name\"==\"$VAULT_NAME\")) | .id" | sed -e 's/"//g'`
  if [ -z "$VAULT_PENDING_OCID" ]
  then
    echo "No vault named $VAULT_NAME pending deletion"
  else
    read -p "Found an existing fault named $VAULT_NAME but it is pending deletion, cancel the deletion and re-use it ?" REPLY
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK will try to create a new vault for you with this name $VAULT_NAME, if you hit resource limits you will need to come back and re-use this vault"
    else
      echo "OK, trying to cancel vault deletion"
      oci kms management vault cancel-deletion --vault-id $VAULT_PENDING_OCID --wait-for-state ACTIVE
    fi
  fi
  VAULT_OCID=`oci kms management vault list --compartment-id $COMPARTMENT_OCID --all | jq -e ".data[] | select ((.\"lifecycle-state\"==\"ACTIVE\") and (.\"display-name\"==\"$VAULT_NAME\")) | .id" | sed -e 's/"//g'`
  if [ -z "$VAULT_OCID" ]
  then
    echo "Vault named $VAULT_NAME doesn't exist, creating it, there may be a short delay"
    VAULT_OCID=`oci kms management vault create --compartment-id $COMPARTMENT_OCID --display-name $VAULT_NAME --vault-type DEFAULT --wait-for-state ACTIVE | jq -j '.data.id'`
    echo "Vault being created using OCID $VAULT_OCID"
    echo "VAULT_OCID=$VAULT_OCID" >>$SETTINGS
    echo "VAULT_REUSED=false" >> $SETTINGS
  else
    echo "Found existing vault names $VAULT_NAME, reusing it"
    echo "VAULT_OCID=$VAULT_OCID" >> $SETTINGS
    echo "VAULT_REUSED=true" >> $SETTINGS
  fi
else
  # We'de been given an VAULT_OCID, let's check if it's there, if so assume it's been configured already
  echo "Trying to locate vault using specified OCID $VAULT_OCID"
  VAULT_NAME=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."display-name"'`
  if [ -z $DBNAME ]
  then
    echo "Unable to locate vault for OCID $VAULT_OCID"
    echo "Please check that the value of VAULT_OCID in $SETTINGS is correct if nor remove or replace it"
    exit 5
  else
    echo "Located vault named $VAULT_NAME with pre-specified OCID of $VAULT_OCID, checking status"
    VAULT_LIFECYCLE=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."lifecycle-state"'`
    if [ $VAULT_LIFECYCLE -ne "ACTIVE" ]
    then
      echo "Vault $VAULT_NAME is not active, cannot use it"
    else
      echo "Vault $VAULT_NAME is active, reusing it"
      # Flag this as reused and refuse to destroy it
      echo "VAULT_REUSED=true" >> $SETTINGS
    fi
  fi
fi
echo "Setting up for Vault master key"
echo "Getting vault endpoint for vault OCID $VAULT_OCID"
VAULT_ENDPOINT=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."management-endpoint"'`
VAULT_KEY_NAME="$USER_INITIALS"Key
echo "Checking for existing key named $VAULT_KEY_NAME in endpoint $VAULT_ENDPOINT in compartment OCID $COMPARTMENT_OCID"

VAULT_PENDING_KEY_OCID=`oci kms management key list --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --all | jq -e ".data[] | select ((.\"lifecycle-state\"==\"PENDING_DELETION\") and (.\"display-name\"==\"$VAULT_KEY_NAME\")) | .id" | sed -e 's/"//g'`
if [ -z "$VAULT_PENDING_KEY_OCID" ]
then
  echo "No key named $VAULT_KEY_NAME pending deletion"
else
  read -p "Found an existing master key named $VAULT_KEY_NAME which is pending deletion, cancel the deletion and reuse it ?" REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK will try to create a new key for you with this name $VAULT_NAME, if you hit resource limits you will need to come back and re-use this vault"
  else
    echo "OK, trying to cancel key deletion"
    oci kms management key cancel-deletion --vault-id $VAULT_PENDING_KEY_OCID --wait-for-state  ENABLED
  fi
fi
VAULT_KEY_OCID=`oci kms management key list --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --all | jq -e ".data[] | select ((.\"lifecycle-state\"==\"ACTIVE\") and (.\"display-name\"==\"$VAULT_KEY_NAME\")) | .id" | sed -e 's/"//g'`
if [ -z $VAULT_KEY_OCID ]
then
  echo "No existing key with name $VAULT_KEY_NAME, creating it"
  VAULT_KEY_OCID=`oci kms management key create --display-name $VAULT_KEY_NAME  --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --key-shape '{"algorithm":"AES", "length":32}' --wait-for-state  ENABLED | jq -j ".data.id" | sed -e 's/"//g'`
  echo "VAULT_KEY_REUSED=false" >> $SETTINGS
else
  echo "Found existing key with name $VAULT_KEY_NAME, reusing it"
  echo "VAULT_KEY_REUSED=true" >> $SETTINGS
fi
echo "VAULT_KEY_OCID=$VAULT_KEY_OCID" >> $SETTINGS

echo "Vault master key created with OCID $VAULT_KEY_OCID"