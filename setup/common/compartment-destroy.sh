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

if [ -z $COMPARTMENT_REUSED ]
then
  echo No reuse information for compartment cannot safely contiue, you will have to destroy it manually
  exit 1
fi

if [ $COMPARTMENT_REUSED = true ]
then
  echo You have been using a comparment that was not created by these scripts, you will need to destroy the compartment by hand
  echo and then remove COMPARTMENT_REUSED and COMPARTMENT_OCID from $SETTINGS 
  exit 2
fi

if [ -z $COMPARTMENT_OCID ]
then 
  echo No compartment OCID information found, cannot destroy something that cant be identifed
  exit 3
fi

TENANCY_NAME=`oci iam tenancy get --tenancy-id=$OCI_TENANCY | jq -j '.data.name'`
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name' | sed -e 's/"//g'`
COMPARTMENT_PARENT_OCID=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data."compartment-id"' | sed -e 's/"//g'`
COMPARTMENT_PARENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_PARENT_OCID | jq -j '.data.name' | sed -e 's/"//g'`

if [ $COMPARTMENT_PARENT_NAME = $TENANCY_NAME ]
then
  PARENT_NAME="Tenancy root"
else 
  PARENT_NAME="$COMPARTMENT_PARENT_NAME sub compartment"
fi


echo Destroying compartment $COMPARTMENT_NAME in $COMPARTMENT_PARENT_NAME This will fail if the compartment is not empty and you will then need to remove any respurce in it and delete it manually
oci iam compartment delete  --compartment-id $COMPARTMENT_OCID


bash ./delete-from-saved-settings.sh COMPARTMENT_OCID
bash ./delete-from-saved-settings.sh COMPARTMENT_REUSED