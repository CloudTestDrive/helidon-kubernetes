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

if [ -z $COMPARTMENT_REUSED ]
then
  echo "No reuse information for compartment cannot safely contiue, you will have to destroy it manually"
  exit 0
fi

if [ $COMPARTMENT_REUSED = true ]
then
  echo "$SCRIPT_NAME You have been using a comparment that was not created by these scripts, you will need to destroy"
  echo "the compartment by hand (assuming it's empty)"
  echo "Going to remove thwe compartment settings so you can easily recreate things if you want"
  bash ./delete-from-saved-settings.sh COMPARTMENT_OCID
  bash ./delete-from-saved-settings.sh COMPARTMENT_REUSED
  exit 0
fi

if [ -z $COMPARTMENT_OCID ]
then 
  echo "No compartment OCID information found, cannot destroy something that cant be identifed"
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

if [ -z $"AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=false
fi


if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Destroy compartment $COMPARTMENT_NAME in $COMPARTMENT_PARENT_NAME  defaulting to $REPLY"
else
  read -p "Destroy compartment $COMPARTMENT_NAME in $COMPARTMENT_PARENT_NAME (y/n) ?" REPLY
fi 
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, compartment $COMPARTMENT_NAME in $COMPARTMENT_PARENT_NAME not destroyed"
  exit 0
else
  echo "OK, proceeding with comparment deletion"
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

echo "Destroying compartment $COMPARTMENT_NAME in $COMPARTMENT_PARENT_NAME This will fail if the compartment is not empty and you will then need to remove any respurce in it and delete it manually"
oci iam compartment delete  --compartment-id $COMPARTMENT_OCID --region $OCI_HOME_REGION --force


bash ./delete-from-saved-settings.sh COMPARTMENT_OCID
bash ./delete-from-saved-settings.sh COMPARTMENT_REUSED