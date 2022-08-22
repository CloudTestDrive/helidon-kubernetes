#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

echo "Use this script if the deployments are out of sync with the repo locations - for example you've reset the scripts file structure"
if [ -z $OCIR_STOCKMANAGER_LOCATION ]
then
  echo "$SCRIPT_NAME No OCIR location found for stockmanager repo have you run the ocir-setup.sh script ?"
  exit 1
fi
if [ -z $OCIR_LOGGER_LOCATION ]
then
  echo "$SCRIPT_NAME No OCIR location found for logger repo have you run the ocir-setup.sh script ?"
  exit 1
fi

if [ -z $OCIR_STOREFRONT_LOCATION ]
then
  echo "$SCRIPT_NAME No OCIR location found for stockmanager repo have you run the ocir-setup.sh script ?"
  exit 1
fi
if [ -z $OCIR_STOCKMANAGER_OCID ]
then
  echo "$SCRIPT_NAME No OCIR ocid found for stockmanager repo have you run the ocir-setup.sh script ?"
  exit 1
fi

if [ -z $OCIR_STOREFRONT_OCID ]
then
  echo "$SCRIPT_NAME No OCIR ocid found for storefront repo have you run the ocir-setup.sh script ?"
  exit 1
fi

# get the tenancy object storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -r '.data'`
# Get the OCIR locations
echo "Locating repo names"
OCIR_STOCKMANAGER_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOCKMANAGER_OCID | jq -r '.data."display-name"'`
OCIR_LOGGER_NAME=`oci artifacts  container repository get  --repository-id $OCIR_LOGGER_OCID | jq -r '.data."display-name"'`
OCIR_STOREFRONT_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOREFRONT_OCID | jq -r '.data."display-name"'`

bash stockmanager-deployment-update.sh set $OCIR_STOCKMANAGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOCKMANAGER_NAME
bash logger-deployment-update.sh set $OCIR_LOGGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_LOGGER_NAME
bash storefront-deployment-update.sh set $OCIR_STOREFRONT_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

