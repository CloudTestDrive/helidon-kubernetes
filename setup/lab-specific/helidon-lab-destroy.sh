#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome the the helidon development specific lab destroy script."
echo "Checking region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
if [ $OCI_REGION = $OCI_HOME_REGION ]
then
  echo "You are in your home region and this script will continue"
else
  echo "You need to run this script in your home region of $OCI_HOME_REGION, you "
  echo "are running it in $OCI_REGION"
  echo "Please switch to your OCI home region in your browser (you will need to"
  echo "restart the cloud shell) and re-run this script"
  exit 1
fi
read -p "Are you running in a free trial account, or in an account where you have full administrator rights ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an adminitrator or in a free trial account this script cannot automatically"
  echo "configure your environment."
  exit 1
fi
echo "This script will:"
echo "  Terminate the database"
echo "  Attempt to remove your working a compartment (this will fail if it contains reeesources you've created)"
echo "  Remove gathered basic information such as your initials"
echo "At completion this will have removed the resources created by the setup scripts, however any resources that"
echo "you configured manually will remain"
echo "You will still need to destroy your virtual machine manually first"

read -p "Do you want to proceed ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting this script"
  exit 0 
fi

echo "This script can in most cases automatically apply a sensible default answer to questions in line with the intent."
echo "to destroy the setup."

read -p "Do you want to use the automatic defaults ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  export AUTO_CONFIRM=false
else
  export AUTO_CONFIRM=true
fi

SAVED_PWD=`pwd`

cd $COMMON_DIR

bash ./core-environment-destroy.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "Core environment destroy returned an error, unable to continue"
  exit $RECP
fi
exit 0