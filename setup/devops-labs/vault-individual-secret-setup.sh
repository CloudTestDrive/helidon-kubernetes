#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 11
fi

if [ -z $VAULT_OCID ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo Found vault
fi

if [ -z $VAULT_KEY_OCID ]
then
  echo "No vault key OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 13
else
  echo Found vault key
fi


## This is specific to the secret being generated

SETTINGS_NAME=OCIR_HOST
VAULT_SECRET_DESCRIPTION='OCIR hostname'

if [ -z $OCIR_STOREFRONT_LOCATION ]
then
  echo "No OCIR host variable for the storefront image set, have you run the image-environment-setup.sh or ocir-setup.sh script ?"
  echo "Cannot continue"
  exit 14
else
  echo "Found storefront host location"
fi

VAULT_SECRET_VALUE=$OCIR_STOREFRONT_LOCATION


## Back to generic code again

VAULT_SECRET_NAME=$SETTINGS_NAME"_VAULT"

if [ -z $VAULT_SECRET_OCIR_HOST_REUSED ] 
then
  echo "No existing reuse information for "$SETTINGS_NAME"_VAULT, continuing"
else
  echo "The "$SETTINGS_NAME"_VAULT secret has already been setup, will not be recreated."
  echo "The OCID for the $VAULT_SECRET_NAME secret is $VAULT_SECRET_OCIR_HOST_OCID"
  exit 0
fi

BASE64_VAULT_SECRET_VALUE=`echo $VAULT_SECRET_VALUE | base64`
#lets see it it exists already
echo "Checking if secret $VAULT_SECRET_NAME already exists"
VAULT_SECRET_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state ACTIVE --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`

VAULT_SECRET_PENDING_DELETION_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state PENDING_DELETION --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`
if [ -z $VAULT_SECRET_PENDING_DELETION_OCID ]
then
  if [ -z $VAULT_SECRET_OCID ]
  then
    echo "secret $VAULT_SECRET_NAME Does not exist, creating it and setting it to $VAULT_SECRET_VALUE"
    # Create the secrets
    VAULT_SECRET_OCID=`oci vault secret create-base64 --compartment-id $COMPARTMENT_OCID --secret-name $VAULT_SECRET_NAME --vault-id $VAULT_OCID --description $VAULT_SECRET_DESCRIPTION --key-id $VAULT_KEY_OCID  --secret-content-content $BASE64_VAULT_SECRET_VALUE | jq -j '.data.id'` 
    echo "VAULT_SECRET_"$SETTINGS_NAME"_OCID=$VAULT_SECRET_OCID" >> $SETTINGS
    echo "VAULT_SECRET_"$SETTINGS_NAME"_REUSED=false" >> $SETTINGS
  else
    # it exists, we will just re-use it
    echo "$VAULT_SECRET_NAME already exists, reusing it, we recommend that you check it contains the value $VAULT_SECRET_VALUE (remember to"
    echo "convert the vault vault from base64 when checking). If you need to change the contents you will have to do that manually"
    echo "VAULT_SECRET_"$SETTINGS_NAME"_OCID=$VAULT_SECRET_OCID" >> $SETTINGS
    echo "VAULT_SECRET_"$SETTINGS_NAME"_REUSED=true" >> $SETTINGS
  fi
  echo "The OCID for the $VAULT_SECRET_NAME secret is $VAULT_SECRET_OCID"
else
  echo "A Vault secret named $VAULT_SECRET_NAME already exists but has a deletion scheduled. It "
  echo "cannot be used unless the deletion is cancled."
  echo "Do you want to cancel the pending deletion ?"
  read -p "Are you running in a free trial environment (y/n) ? " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you cannot use the secret name $VAULT_SECRET_NAME, you can manually create another secret"
    echo "to hold this information with value $VAULT_SECRET_VALUE and use it's OCID in the labs"
    exit 1
  else
    echo "OK, canceling pending deletion"
    oci vault secret cancel-secret-deletion --secret-id  $VAULT_SECRET_PENDING_DELETION_OCID
    echo "Pending deletion cancled, please ensure that the value of the secret $VAULT_SECRET_NAME is set to $VAULT_SECRET_VALUE"
    echo "Optionally you can re-run this script"
  fi
fi
