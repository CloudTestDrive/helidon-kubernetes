#!/bin/bash -f

if [ $# -lt 3 ]
then
  echo "The vault key setup script requires three arguments:"
  echo "the name of the key to create this will be prefixed with your user initials in the vault"
  echo "the key type e.g. AES or RSA"
  echo "the key size for AES this is maybe 32, for RAS then maybe 2048 or 4096"
  exit 1
fi

VAULT_KEY_PROVIDED_NAME=$1
VAULT_KEY_NAME="$USER_INITIALS""$VAULT_KEY_PROVIDED_NAME"
VAULT_KEY_TYPE=$2
VAULT_KEY_SIZE=$3

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
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

if [ -z "$VAULT_OCID" ]
then
  echo "Your vault ocid has not been set, you need to run the vault-setup.sh script before you can run this script"
  exit 1
fi
if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi
# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
VAULT_KEY_REUSED_NAME=`bash vault-key-get-var-name-reused.sh $VAULT_KEY_NAME`
# Now locate the value of the variable who's name is in VAULT_KEY_REUSED_NAME and save it
VAULT_KEY_REUSED="${!VAULT_KEY_REUSED_NAME}"
if [ -z $VAULT_KEY_REUSED ]
then
  echo "No reuse information for vault key $VAULT_KEY_NAME"
else
  echo "This script has already configured vault key $VAULT_KEY_NAME exiting"
  exit 0
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
VAULT_KEY_OCID_NAME=`bash vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`

echo "Getting vault into for vault OCID $VAULT_OCID"
VAULT_ENDPOINT=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."management-endpoint"'`
VAULT_NAME=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."display-name"'`

if [ -z "$VAULT_KEY_REUSED" ]
then
  echo "No resuse information for the key, setting up for Vault master key"
    echo "Checking for existing key named $VAULT_KEY_NAME in endpoint $VAULT_ENDPOINT in compartment OCID $COMPARTMENT_OCID"
  SCHEDULING_DELETION_KEY_OCID=`oci kms management key list --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"SCHEDULING_DELETION\") and (.\"display-name\"==\"$VAULT_KEY_NAME\"))] | first | .id"`
  if [ -z "$SCHEDULING_DELETION_KEY_OCID" ]
  then
    SCHEDULING_DELETION_KEY_OCID=null
  fi
  if [ "$SCHEDULING_DELETION_KEY_OCID" = "null" ]
  then
    echo "No key named $VAULT_KEY_NAME in scheduling deletion state in vault $VAULT_NAME, continuing"
  else
    echo "There is a key named $VAULT_KEY_NAME in vault $VAULT_NAME that currently has a scheduling deletion activity"
    echo "underway, please wait until that has finished (this may take a few mins) then re-run"
    echo "this script to cancel the deletion and re-use that key"
    exit 1
  fi
  VAULT_PENDING_KEY_OCID=`oci kms management key list --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"PENDING_DELETION\") and (.\"display-name\"==\"$VAULT_KEY_NAME\"))] | first | .id"`
  if [ -z "$VAULT_PENDING_KEY_OCID" ]
  then
    VAULT_PENDING_KEY_OCID=null
  fi
  VAULT_KEY_UNDELETED=false
  if [ "$VAULT_PENDING_KEY_OCID" = "null" ]
  then
    echo "No key named $VAULT_KEY_NAME pending deletion"
  else
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, Found an existing master key named $VAULT_KEY_NAME in vault $VAULT_NAME which is pending deletion, cancel the deletion and reuse it defaulting to $REPLY"
    else
      read -p "Found an existing master key named $VAULT_KEY_NAME in vault $VAULT_NAME which is pending deletion, cancel the deletion and reuse it (y/n) ?" REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK will try to create a new key for you with this name $VAULT_NAME in vault $VAULT_NAME , if you hit resource limits you will need to come back and re-use this vault"
    else
      echo "OK, trying to cancel key deletion"
      oci kms management key cancel-deletion --key-id $VAULT_PENDING_KEY_OCID --endpoint $VAULT_ENDPOINT  --wait-for-state  ENABLED
      VAULT_KEY_UNDELETED=true
    fi
  fi
  VAULT_KEY_OCID=`oci kms management key list --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --all | jq -j "[.data[] | select ((.\"lifecycle-state\"==\"ENABLED\") and (.\"display-name\"==\"$VAULT_KEY_NAME\"))] | first | .id" `
  if [ -z $VAULT_KEY_OCID ]
  then
    VAULT_KEY_OCID=null
  fi
  if [ "$VAULT_KEY_OCID" = "null" ]
  then
    echo "No existing key with name $VAULT_KEY_NAME, creating it"
    KEY_SHAPE="{\"algorithm\":\"$VAULT_KEY_TYPE\", \"length\":$VAULT_KEY_SIZE}"
    VAULT_KEY_OCID=`oci kms management key create --display-name $VAULT_KEY_NAME  --compartment-id $COMPARTMENT_OCID --endpoint $VAULT_ENDPOINT --key-shape "$KEY_SHAPE" --wait-for-state  ENABLED | jq -j ".data.id"`
    echo "$VAULT_KEY_REUSED_NAME=false" >> $SETTINGS
  else
    echo "Found existing key with name $VAULT_KEY_NAME, reusing it"
    # if the vault itself was undeleted then in practical terms the key will have been as well
    # so allow it to be deleted anyway
    if [ "$VAULT_UNDELETED" = "true" ]
    then
      VAULT_KEY_UNDELETED=true
    fi
    # if we undeleted the key then the delete script can undelete it as well
    if [ "$VAULT_KEY_UNDELETED" = "true" ]
    then
      echo "$VAULT_KEY_REUSED_NAME=false" >> $SETTINGS
    else
      echo "$VAULT_KEY_REUSED_NAME=true" >> $SETTINGS
    fi
  fi
  echo "$VAULT_KEY_OCID_NAME=$VAULT_KEY_OCID" >> $SETTINGS
  echo "Vault master key created with OCID $VAULT_KEY_OCID"
else
  echo "Vault key reuse information found, checking validity"
  if [ -z "$VAULT_KEY_OCID" ]
  then
    echo "No VAULT_KEY_OCID available in the state file ( $SETTINGS )"
    echo "Edit the state file and provide the VAULT_KEY_OCID or remove VAULT_KEY_REUSED"
    echo 12
  fi
  VAULT_KEY_NAME=`oci kms management key get --key-id $VAULT_KEY_OCID --endpoint $VAULT_ENDPOINT | jq -j '.data."display-name"'`
  if [ -z "$VAULT_KEY_NAME" ]
  then
    VAULT_KEY_NAME=null
  fi
  if [ "$VAULT_KEY_NAME" = "null" ]
  then
    echo "Unable to retrieve details of vault with OCID $VAULT_KEY_OCID, please check that it hasn't been deleted"
    exit 13
  else
    echo "Vault key with OCID $VAULT_KEY_OCID is named $VAULT_KEY_NAME"
  fi
fi