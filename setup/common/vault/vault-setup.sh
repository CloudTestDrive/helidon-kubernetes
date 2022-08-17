#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f "$SETTINGS" ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi


if [ -z "$USER_INITIALS" ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 1
fi


if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z "$COMPARTMENT_NAME" ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS"
  exit 99
else
  echo "Operating in compartment $COMPARTMENT_NAME"
fi
# assume that the vault is not undeleted
VAULT_UNDELETED=false
if [ -z "$VAULT_REUSED" ]
then
  echo "No reuse information for vault"

  VAULT_NAME="$USER_INITIALS"LabsVault
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled,  use $VAULT_NAME as the name of the vault to create or re-use in $COMPARTMENT_NAME defaulting to $REPLY"
  else
    read -p "Do you want to use $VAULT_NAME as the name of the vault to create or re-use in $COMPARTMENT_NAME (y/n) ?" REPLY
  fi
  
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]
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
  if [ -z "$VAULT_OCID" ]
    then
    # No existing VAULT_OCID so need to potentially create it
    echo "Checking for  vault $VAULT_NAME in compartment $COMPARTMENT_NAME"
    SCHEDULING_DELETION_VAULT_OCID=`oci kms management vault list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"SCHEDULING_DELETION\") and (.\"display-name\"==\"$VAULT_NAME\"))] | first | .id" `
    if [ -z "$SCHEDULING_DELETION_VAULT_OCID" ]
    then
      SCHEDULING_DELETION_VAULT_OCID=null
    fi
    if [ "$SCHEDULING_DELETION_VAULT_OCID" = "null" ]
    then
      echo "No vaults named $VAULT_NAME in scheduling deletion state, continuing"
    else
      echo "There is a vault named $VAULT_NAME that currently has a scheduling deletion activity"
      echo "underway, please wait until that has finished (this may take a few mins) then re-run"
      echo "this script to cancel the deletion and re-use that vault"
      exit 2
    fi
    VAULT_PENDING_OCID=`oci kms management vault list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"PENDING_DELETION\") and (.\"display-name\"==\"$VAULT_NAME\"))] | first | .id" `
    if [ -z "$VAULT_PENDING_OCID" ]
    then
      VAULT_PENDING_OCID=null
    fi
    if [ "$VAULT_PENDING_OCID" = "null" ]
    then
      echo "No vault named $VAULT_NAME pending deletion, continuing"
    else
      if [ "$AUTO_CONFIRM" = true ]
      then
        REPLY="y"
        echo "Auto confirm is enabled,  found an existing vault named $VAULT_NAME but it is pending deletion, cancel the deletion and re-use it defaulting to $REPLY"
      else
        read -p "Found an existing fault named $VAULT_NAME but it is pending deletion, cancel the deletion and re-use it (y/n) ?" REPLY
      fi
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo "OK will try to create a new vault for you with this name $VAULT_NAME"
      else
        echo "OK, trying to cancel vault deletion"
        oci kms management vault cancel-deletion --vault-id $VAULT_PENDING_OCID --wait-for-state ACTIVE
        VAULT_UNDELETED=true
      fi
    fi
    VAULT_OCID=`oci kms management vault list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"ACTIVE\") and (.\"display-name\"==\"$VAULT_NAME\"))] | first | .id" `
    if [ -z "$VAULT_OCID" ]
    then
      VAULT_OCID=null
    fi
    if [ "$VAULT_OCID" = "null" ]
    then
      # check for resource availability
      bash ./resources/resource-minimum-check-region-compartment.sh $COMPARTMENT_OCID kms virtual-vault-count 1
      if [ $? = 0 ]
      then
        echo "Vault resources are available, continuing"
      else
        echo "No vault resources available, cannot continue"
        exit 10
      fi
      echo "Vault named $VAULT_NAME doesn't exist, creating it, there may be a short delay"
      VAULT_OCID=`oci kms management vault create --compartment-id $COMPARTMENT_OCID --display-name $VAULT_NAME --vault-type DEFAULT --wait-for-state ACTIVE | jq -j '.data.id'`
      echo "Vault being created using OCID $VAULT_OCID"
      echo "VAULT_OCID=$VAULT_OCID" >>$SETTINGS
      echo "VAULT_REUSED=false" >> $SETTINGS
    else
      echo "Found existing vault names $VAULT_NAME, reusing it"
      echo "VAULT_OCID=$VAULT_OCID" >> $SETTINGS
      # if we undeleted the vault then the delete script can undelete it as well
      if [ "$VAULT_UNDELETED" = "true" ]
      then
        echo "VAULT_REUSED=false" >> $SETTINGS
      else
        echo "VAULT_REUSED=true" >> $SETTINGS
      fi
    fi
  else
    # We've been given an VAULT_OCID, let's check if it's there, if so assume it's been configured already
    echo "Trying to locate vault using specified OCID $VAULT_OCID"
    VAULT_NAME=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."display-name"'`
    if [ -z "$VAULT_NAME" ]
    then
      VAULT_NAME=null
    fi
    if [ "$VAULT_NAME" = "null" ]
    then
      echo "Unable to locate vault for OCID $VAULT_OCID"
      echo "Please check that the value of VAULT_OCID in $SETTINGS is correct if nor remove or replace it"
      exit 5
    else
      echo "Located vault named $VAULT_NAME with pre-specified OCID of $VAULT_OCID, checking status"
      VAULT_LIFECYCLE=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."lifecycle-state"'`
      if [ "$VAULT_LIFECYCLE" -ne "ACTIVE" ]
      then
        echo "Vault $VAULT_NAME is not active, cannot use it"
      else
        echo "Vault $VAULT_NAME is active, reusing it"
        echo "VAULT_REUSED=true" >> $SETTINGS
      fi
    fi
  fi
else
  echo "This script has already configured vault details"
  if [ -z "$VAULT_OCID" ]
  then
    echo "No VAULT_OCID available in the state file ( $SETTINGS )"
    echo "Edit the state file and provide the VAULT_OCID or remove VAULT_REUSED"
    echo 12
  fi
  VAULT_NAME=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."display-name"'`
  if [ -z "$VAULT_NAME" ]
  then
    VAULT_NAME=null
  fi
  if [ "$VAULT_NAME" = "null" ]
  then
    echo "Unable to retrieve details of vault with OCID $VAULT_OCID, please check that it hasn't been deleted"
    exit 13
  else
    echo "Vault with OCID $VAULT_OCID is named $VAULT_NAME"
  fi
fi

echo "VAULT_UNDELETED=$VAULT_UNDELETED" >> $SETTINGS
