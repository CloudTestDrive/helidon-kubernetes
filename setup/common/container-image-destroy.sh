#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot continue
    exit 10
fi


if [ -z $OCIR_STOCKMANAGER_OCID ]
then
  echo 'No OCIR id found for stockmanager repo have you run the ocir-setup.sh script ?'
  exit 1
fi

if [ -z $OCIR_STOREFRONT_OCID ]
then
  echo 'No OCIR id found for storefront repo have you run the ocir-setup.sh script ?'
  exit 1
fi

# storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`


echo Removing stockmanager images

# Get the OCIR location

OCIR_STOCKMANAGER_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOCKMANAGER_OCID | jq -r '.data."display-name"'`


bash stockmanager-deployment-update.sh reset $OCIR_STOREFRONT_LOCATION $OCIR_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

IMAGE_STOCKMANAGER_LATEST=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:latest`

if [ -z $IMAGE_STOCKMANAGER_LATEST ]
then
  echo Cant locate latest stock manager image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOCKMANAGER_LATEST
  echo Removed stockmanager latest
fi

IMAGE_STOCKMANAGER_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.1`
if [ -z $IMAGE_STOCKMANAGER_V001 ]
then
  echo Cant locate 0.0.1 stock manager image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOCKMANAGER_V001
  echo Removed stockmanager 0.0.1
fi
IMAGE_STOCKMANAGER_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.2`
if [ -z $IMAGE_STOCKMANAGER_V002 ]
then
  echo Cant locate 0.0.2 stock manager image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOCKMANAGER_V002
  echo Removed stockmanager 0.0.2
fi

echo Removing storefront images

OCIR_STOREFRONT_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOREFRONT_OCID | jq -r '.data."display-name"'`

bash storefront-deployment-update.sh reset $OCIR_STOREFRONT_LOCATION $OCIR_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

IMAGE_STOREFRONT_LATEST=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:latest`

if [ -z $IMAGE_STOREFRONT_LATEST ]
then
  echo Cant locate latest sstorefront image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOREFRONT_LATEST
  echo Removed storefront latest
fi

IMAGE_STOREFRONT_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.1`
if [ -z $IMAGE_STOREFRONT_V001 ]
then
  echo Cant locate 0.0.1 storefront image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOREFRONT_V001
  echo Removed storefront 0.0.1
fi
IMAGE_STOREFRONT_V001=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.2`
if [ -z $IMAGE_STOREFRONT_V002 ]
then
  echo Cant locate 0.0.2 storefront image, skipping
else
  oci artifacts container image remove-version --image-id $IMAGE_STOREFRONT_V002
  echo Removed storefront 0.0.2
fi