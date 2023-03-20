#!/bin/bash -f

SCRIPT_NAME=`basename $0`
if [ $# -ne 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "1st is the name of the setting e.g. OCIR_HOST - the script will appeneded / prepend the required strings around that value"
fi
SETTINGS_NAME=$1

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

SECRET_NAME=`./bash get-vault-secret-name.sh $SETTINGS_NAME`
VAULT_SECRET_NAME=`bash ./get-vault-secret-name.sh $SECRET_NAME`
VAULT_SECRET_OCID_NAME=`bash ./get-vault-secret-ocid-name.sh $SECRET_NAME`
VAULT_SECRET_REUSED_NAME=`bash ./get-vault-secret-reused-name.sh $SECRET_NAME`

if [ -z "${!VAULT_SECRET_REUSED_NAME}" ] 
then
  echo "No existing reuse information for vault secret "$SETTINGS_NAME" , perhaps it's already been removed ? Nothing to delete"
  exit 0
fi

if [ "${!VAULT_SECRET_REUSED_NAME}"  = true ] 
then
  echo "The secret $SETTINGS_NAME was not created by this script, will not delete it"
  exit 0
fi

if [ -z "${!VAULT_SECRET_OCID_NAME}" ] 
then
  echo "The OCID of secret $SETTINGS_NAME (stored in variable $VAULT_SECRET_OCID_NAME) is not in the $SETTINGS file, cannot proceed"
  exit 13
fi

echo "Scheduling deletion of secret $SETTINGS_NAME"
echo "The actuall deletion will happen later (usually in a month) and you can cancel the"
echo "deletion in the intervening time if you wish."
echo "If you re-run this lab while the secrets deletion is still pending you will need to"
echo "Cancel the deletion and ensure that the value in the secret is what you require. If"
echo "it's not then you can using the OCI Vault UI create a new version of the secret with"
echo "the value you want"
echo "Note, a secret that is pending deletion will prevent the compartment that contains it from being deleted"

oci vault secret schedule-secret-deletion --secret-id "${!VAULT_SECRET_OCID_NAME}"
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure deleting the vault secret $SETTINGS_NAME, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# clean up the settings
bash ../delete-from-saved-settings.sh "$VAULT_SECRET_OCID_NAME"
bash ../delete-from-saved-settings.sh "$VAULT_SECRET_REUSED_NAME"
