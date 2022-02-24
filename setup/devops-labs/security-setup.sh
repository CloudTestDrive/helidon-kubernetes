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

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script
  exit 2
fi


# get the compartment parent
COMPARTMENT_PARENT_OCID=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data."compartment-id"'`

# work out the parent's name
if [ $OCI_TENANCY = $COMPARTMENT_PARENT_OCID ]
then
   COMPARTMENT_PARENT_NAME="Tenancy root"
else
   COMPARTMENT_PARENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_PARENT_OCID | jq -r '.data.name'`
fi

read -p "Are you running in a free trial environment or running with administrator rights to the compartment $COMPARTMENT_PARENT_NAME (y/n) ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "You will need to follow the manual instructions to setup the user group, the dynamic"
  echo "Groups and associated policies"
  echo "If you are a federated user you may also need to setup the user group in your"
  echo "Federated environment, add your usert to it, then map that federated group to your"
  echo "local group"
  exit 1
else
  echo "OK, starting security setup"
  bash ./dynamic-groups-setup.sh
  bash ./policies-setup.sh
fi