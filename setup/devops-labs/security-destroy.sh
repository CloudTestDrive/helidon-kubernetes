#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
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
  echo "You will need to follow the manual instructions to delete the users ssh API key, ther user"
  echo "group, the dynamic groups and associated policies"
  echo "If you are a federated user you may also need unmap the federated group from the local"
  echo "group, then remove your user and federated group from your federated environment"
else
  echo "Starting security setting clean up"
  bash ./policies-destroy.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure destroying the policies, exit code is $RESP, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi 
  bash ./dynamic-groups-destroy.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure destroying the dynamic groups, exit code is $RESP, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi 
fi
echo "SSH key removal starting"
bash ./ssh-api-key-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the ssh key, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 