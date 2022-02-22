#!/bin/bash -f

if [ $# -ne 1 ]
then
  echo "This script $0 requires one argument:"
  echo "1st is the name of the setting e.g. OCIR_HOST - the script will appeneded / prepend the required strings around that value"
fi
SETTINGS_NAME=$1


export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot continue
    exit 10
fi

VAULT_SECRET_NAME=$SETTINGS_NAME"_VAULT"
VAULT_SECRET_OCID_NAME="VAULT_SECRET_"$SETTINGS_NAME"_OCID"
SECRET_REUSED_VAR_NAME="VAULT_SECRET_"$SETTINGS_NAME"_REUSED"

if [ -z "${!SECRET_REUSED_VAR_NAME}" ] 
then
  echo "No existing reuse information for "$SETTINGS_NAME"_VAULT, cannot continue"
  exit 11
fi

if [ "${!SECRET_REUSED_VAR_NAME}"  = true ] 
then
  echo "The secret $VAULT_SECRET_NAME was not created by this script, will not delete it"
  exit 12
fi

if [ -z "${!VAULT_SECRET_OCID_NAME}" ] 
then
  echo "The OCID of secret $VAULT_SECRET_NAME (stored in variable $VAULT_SECRET_OCID_NAME) is not in the $SETTINGS file, cannot proceed"
  exit 13
fi

echo "Scheduling deletion of secret $VAULT_SECRET_NAME"
echo "The actuall deletion will happen later (usually in a month) and you can cancel the"
echo "deletion in the intervening time if you wish."
echo "If you re-run this lab while the secrets deletion is still pending you will need to"
echo "Cancel the deletion and ensure that the value in the secret is what you require. If"
echo "it's not then you can using the OCI Vault UI create a new version of the secret with"
echo "the value you want"
echo "Note, a secret that is pending deletion will prevent the compartment that contains it from being deleted"
oci vault secret schedule-secret-deletion --secret-id "${!VAULT_SECRET_OCID_NAME}"

# clean up the settings
bash ../delete-from-saved-settings.sh "$VAULT_SECRET_OCID_NAME"
bash ../delete-from-saved-settings.sh "$SECRET_REUSED_VAR_NAME"
