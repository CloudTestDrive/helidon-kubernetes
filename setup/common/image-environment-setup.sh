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

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "Getting region environment details"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
echo "This script will run the required commands to setup your own images"
echo "It assumes you are working in a free trial environment"
echo "If you are not you will need to exit at the prompt and follow the lab instructions for setting up the configuration separatly"
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, in free trial defaulting to $REPLY"
else
  read -p "Are you running in a free trial environment (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  if [ $OCI_REGION = $OCI_HOME_REGION ]
  then
    echo "You are in your home region and this script will continue"
    SAFE_TO_BUILD=true
  else
    echo "You need to run this script in your home region of $OCI_HOME_REGION, you are running it in $OCI_REGION"
    echo "Please switch to your OCI home region and re-run this script"
    SAFE_TO_BUILD=false
  fi
else
  SAFE_TO_BUILD=true
  echo "Thank you for confirming you are in a free trial, let's set your container image environment up"
fi

if [ $SAFE_TO_BUILD = true ]
then
  bash auth-token-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure creating the auth token, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi
  bash ocir-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure creating the OCIR repos, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi
  bash container-image-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure creating the container images, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi
else
  echo "OK, you will need to do the following in the $HOME/helidon-kubernetes/setup/common directory "
  echo "In your HOME REGION of $OCI_HOME_REGION (you are currently in $OCI_REGION) you will need"
  echo "to setup the auth token using the script, this script will stop if it's not in your home region"
  echo "bash auth-token-setup.sh"
  echo "Then run the following in the region you want to run the labs in"
  echo "Please run them in this order"
  echo "bash ocir-setup.sh"
  echo "bash container-image-setup.sh"
  exit 1
fi

bash ./delete-from-saved-settings.sh IMAGES_READY
echo "IMAGES_READY=true" >> $SETTINGS
