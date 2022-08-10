#!/bin/bash -f

if [ $# -lt 1 ]
then
  echo "The vault key setup script requires one arguments:"
  echo "the name of the key to destroy this will have be prefixed with your user initials in the vault"
  exit 1
fi
VAULT_KEY_PROVIDED_NAME=$1
VAULT_KEY_NAME="$USER_INITIALS""$VAULT_KEY_PROVIDED_NAME"
export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
VAULT_KEY_REUSED_NAME=`bash vault-key-get-var-name-reused.sh $VAULT_KEY_NAME`
# Now locate the value of the variable who's name is in VAULT_KEY_REUSED_NAME and save it
VAULT_KEY_REUSED="${!VAULT_KEY_REUSED_NAME}"

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
VAULT_KEY_OCID_NAME=`bash vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`

# Now locate the value of the variable who's name is in VAULT_KEY_OCID_NAME and save it
VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"

if [ -z $VAULT_OCID ]
then
  echo "Cannot locate OCID for the vault , unable to proceed with key of vault deletion"
  exit 0
else
  echo "Locating vault endpoint" 
  VAULT_ENDPOINT=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."management-endpoint"'`
fi

if [ -z $VAULT_KEY_REUSED ]
then
  echo "No reuse information for vault key, cannot safely proceed to schedule it's deletion"
else
  if [ $VAULT_KEY_REUSED = true ]
  then
    echo "The vault key was reused, cannot safely schedule it's deletion, you will have to delete it by hand"
  else
    if [ -z $VAULT_KEY_OCID ]
    then
      echo "Cannot locate OCID for the vault key, unable to schedule it's deletion"
    else
      echo "Scheduling deletion of key, this will normally take effect in a months time"
      echo "should you with to cancel during that time you can do so."
      echo "While deletion is pending any secretes encrypted by this key will be unavailable unless the"
      echo "key deletion is cancled, this will also require that you cancel the vault deletion"
      echo "as you can't have a active key in a vault that is itself pending deletion"
      echo "Note, a key that is pending deletion will prevent the compartment that contains it from being deleted"
      NEW_KEY_STATE=`oci kms management key schedule-deletion --key-id $VAULT_KEY_OCID --endpoint $VAULT_ENDPOINT | jq -j '.data."lifecycle-state"'`
      echo "Keys lifecycle state is $NEW_KEY_STATE" 
      echo "Removing details from the settings file"
      bash ./delete-from-saved-settings.sh $VAULT_KEY_OCID_NAME
      bash ./delete-from-saved-settings.sh $VAULT_KEY_REUSED_NAME
    fi
  fi
fi