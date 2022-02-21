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

# now actually create the host ane nameslace secrets

if [ -z $OCIR_STOREFRONT_LOCATION ]
then
  echo "No OCIR host variable for the storefront image set, have you run the image-environment-setup.sh or ocir-setup.sh script ?"
  echo "Cannot continue setting up this secret"
else
  bash vault-individual-secret-setup.sh OCIR_HOST 'OCIR hostname' $OCIR_STOREFRONT_LOCATION
fi

# the object storage namespace should exist as it's a tenancy level property, so no need to check
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

bash vault-individual-secret-setup.sh OCIR_STORAGE_NAMESPACE 'OCIR Storage namespace' $OBJECT_STORAGE_NAMESPACE