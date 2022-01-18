#!/bin/bash -f
echo "This script will run the required commands to setup your own images"
echo "It assumes you are working in a free trial environment"
echo "If you are not you will need to exit at the prompt and follow the lab instructions for setting up the configuration separatly"
read -p "Are you running in a free trial environment (y/n) ? " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
  OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
  echo "OK, you are not in a free trial you will need to do the following in the $HOME/helidon-kubernetes/setup/common directory "
  echo "In your HOME REGION of $OCI_HOME_REGION (you are currently in $OCI_REGION) you will need"
  echo "to setup the auth token using the script, this script will stop if it's not in your home region"
  echo "bash auth-token-setup.sh"
  echo "Then run the following in the region you want to run the labs in"
  echo "Please run them in this order"
  echo "bash ocir-setup.sh"
  echo "bash container-image-setup.sh"
  exit 1
else
  echo "Thank you for confirming you are in a free trial, let's set your container image environment up"
fi

bash auth-token-setup.sh
bash ocir-setup.sh
bash container-image-setup.sh