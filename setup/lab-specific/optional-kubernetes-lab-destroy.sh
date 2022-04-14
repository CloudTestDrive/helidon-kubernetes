#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome the the Optional Kubernetes specific lab destroy script."
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
  echo "Unfortunately if you are not an administrator or in a free trial account this script cannot automatically"
  echo "configure your environment. You can probabaly still run the labs however. Please follow the instructions"
  echo "in the lab documentation to manually configure your environment"
  exit 1
fi

echo "This script will destroy the Kubernetes services environment:"
echo "  It will attempt to delete any namespaces setup in the optional labs (monitoring, logging and linkerd)"
echo "  Delete the microservices images and repos in OCIR"
echo "  Delete the auth token created to access OCIR (it will not logout of docker though)"
echo "  Reset the Kubernetes cluster to it's defult state by deleting the microservices and related objects"
echo "  Reset the Kubernetes configfuration files (ingress rules, config info etc.)"
echo "  Terminate the Kubernetes cluster"
echo "  Terminate the database and destroy test data"
echo "  Attempt to remove your working a compartment (this will fail if it contains resources you've created)"
echo "  Remove gathered basic information such as your initials"
echo "  Remove the downloaded step certificate manager and certificats it's generated"
echo "At completion this will have removed the resources created by the setup scripts, however any resources that"
echo "you configured manually (for example your devops project) will remain"

read -p "Do you want to proceed ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting this script"
  exit 0 
fi

echo "This script can in most cases automatically apply a sensible default answer to questions (for example the name used"
echo "for the database or the compartment location). Alternatively you can specify answers manually which would let you"
echo "chose customise names and locations."
echo "Note that for some inputs (e.g. entering your initials) it is not possible to make an automatic guess, in those cases"
echo "you will still be prompted for input."

read -p "Do you want to use the automatic defaults ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   export AUTO_CONFIRM=false
else
   export AUTO_CONFIRM=true
fi

SAVED_PWD=`pwd`

cd $MODULES_DIR

bash ./kubernetes-services-destroy-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services destroy module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD
cd $MODULES_DIR

bash ./core-kubernetes-destroy-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Core Kubernetes destroy module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD



exit 0