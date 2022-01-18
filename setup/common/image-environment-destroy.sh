#!/bin/bash -f

echo "This script will run the required commands to destroy the container images setup for the lab"
echo "It will only destroy repositories and tokens created by these scripts, if you reused an existing resource"
echo "then those resources will not be destroyed, and neither will the compartment containing them"
read -p "Are you sure you want to destroy these resources (y/n) ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, stopping script"
  exit 0
fi
echo "This script assumes you are working in a free trial environment"
echo "If you are not you will need to exit at the prompt and follow the lab instructions for setting up the configuration separatly"
read -p "Are you running in a free trial environment (y/n) ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
  OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
  echo "OK, you are not in a free trial you will need to do the following in the $HOME/helidon-kubernetes/setup/common directory "
  echo "Run the following in the region you ran the labs in"
  echo "Please run them in this order"
  echo "bash container-image-destroy.sh"
  echo "bash ocir-destroy.sh"
  echo "In your HOME REGION of $OCI_HOME_REGION (you are currently in $OCI_REGION) you will need"
  echo "to destroy the auth token using the script, this script will stop if it's not in your home region"
  echo "bash auth-token-destroy.sh"
  exit 1
else
  echo "Thank you for confirming you are in a free trial, let's clean your container image environment up"
fi

bash container-image-destroy.sh
bash ocir-destroy.sh
bash auth-token-destroy.sh