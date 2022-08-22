#!/bin/bash -f
SCRIPT_NAME=`basename $0`

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

if [ -z $VAULT_OCID ]
then
  echo "Cannot locate OCID for the vault , unable to proceed with key of vault deletion"
  exit 0
fi

if [ -z $VAULT_REUSED ]
then
  echo "No reuse information for vault , cannot safely proceed to schedule it's deletion"
else
  if [ $VAULT_REUSED = true ]
  then
    echo "The vault was reused, cannot safely schedule it's deletion, you will have to delete it by hand"
  else
    if [ -z $VAULT_OCID ]
    then
      echo "Cannot locate OCID for the vault , unable to schedule it's deletion"
    else
      echo "Scheduling deletion of vault, this will normally take effect in a months time"
      echo "should you with to cancel during that time you can do so."
      echo "While deletion is pending any secretes in this vault will be unavailable unless"
      echo "The vault deletion is cancled"
      echo "Note, a vault that is pending deletion will prevent the compartment that contains it from being deleted"
      NEW_VAULT_STATE=`oci kms management vault schedule-deletion --vault-id $VAULT_OCID | jq -j '.data."lifecycle-state"'`
      echo "Vaults lifecycle state is $NEW_VAULT_STATE" 
      echo "Removing details from the settings file"
      bash ../delete-from-saved-settings.sh VAULT_OCID
      bash ../delete-from-saved-settings.sh VAULT_REUSED
      bash ../delete-from-saved-settings.sh VAULT_UNDELETED
    fi
  fi
fi