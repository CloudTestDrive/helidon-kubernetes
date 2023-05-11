#!/bin/bash -f

if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one arguments:"
  echo "Base name of the OCIR repo"
  exit 1
fi

OCIR_BASE_NAME=$1

echo "Signing images for $OCIR_BASE_NAME/logger (0.0.1), $OCIR_BASE_NAME/storefront (0.0.1, 0.0.2) and $OCIR_BASE_NAME/stockmanager (0.0.1, 0.0.2)"

SAVED_DIR=`pwd`
cd ocir

# Get the OCIR locations
echo "Locating repo names"

OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront


bash ./ocir-image-sign.sh $OCIR_LOGGER_NAME 0.0.1 RSA
bash ./ocir-image-sign.sh $OCIR_STOCKMANAGER_NAME 0.0.1 RSA
bash ./ocir-image-sign.sh $OCIR_STOCKMANAGER_NAME 0.0.2 RSA
bash ./ocir-image-sign.sh $OCIR_STOREFRONT_NAME 0.0.1 RSA
bash ./ocir-image-sign.sh $OCIR_STOREFRONT_NAME 0.0.2 RSA