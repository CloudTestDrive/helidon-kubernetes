#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi



if [ -z $OCIR_BASE_NAME ]
then
  echo 'No base name found,  have you run the ocir-setup.sh script ?'
  exit 1
fi

# storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`


# Get the OCIR locations
echo "Locating repo names"

OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront

bash stockmanager-deployment-update.sh reset $OCIR_STOCKMANAGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOCKMANAGER_NAME
IMAGE_STOCKMANAGER_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOCKMANAGER_V001 ]
then
  IMAGE_STOCKMANAGER_V001="null"
fi
if [ "$IMAGE_STOCKMANAGER_V001" = "null" ]
then
  echo "Cant locate 0.0.1 stock manager image, skipping"
else
  oci artifacts container image delete --force --image-id $IMAGE_STOCKMANAGER_V001
  echo "Removed stockmanager 0.0.1"
fi
IMAGE_STOCKMANAGER_V002=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.2 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOCKMANAGER_V002 ]
then
  IMAGE_STOCKMANAGER_V002="null"
fi
if [ "$IMAGE_STOCKMANAGER_V002" = "null" ]
then
  echo "Cant locate 0.0.2 stock manager image, skipping"
else
  oci artifacts container image delete --force --image-id $IMAGE_STOCKMANAGER_V002
  echo "Removed stockmanager 0.0.2"
fi

bash logger-deployment-update.sh reset $OCIR_LOGGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_LOGGER_NAME

IMAGE_LOGGER_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_LOGGER_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_LOGGER_V001 ]
then
  IMAGE_LOGGER_V001="null"
fi
if [ "$IMAGE_LOGGER_V001" = "null" ]
then
  echo "Cant locate 0.0.1 logger image, skipping"
else
  oci artifacts container image delete --force --image-id $IMAGE_LOGGER_V001
  echo "Removed logger 0.0.1"
fi

bash storefront-deployment-update.sh reset $OCIR_STOREFRONT_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

IMAGE_STOREFRONT_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOREFRONT_V001 ]
then
  IMAGE_STOREFRONT_V001="null"
fi
if [ "$IMAGE_STOREFRONT_V001"="null" ]
then
  echo "Cant locate 0.0.1 storefront image, skipping"
else
  oci artifacts container image delete --force  --image-id $IMAGE_STOREFRONT_V001
  echo "Removed storefront 0.0.1"
fi
IMAGE_STOREFRONT_V002=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.2 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOREFRONT_V002 ]
then
  IMAGE_STOREFRONT_V002="null"
fi
if [ "$IMAGE_STOREFRONT_V002"="null" ]
then
  echo "Cant locate 0.0.2 storefront image, skipping"
else
  oci artifacts container image delete --force --image-id $IMAGE_STOREFRONT_V002
  echo "Removed storefront 0.0.2"
fi
