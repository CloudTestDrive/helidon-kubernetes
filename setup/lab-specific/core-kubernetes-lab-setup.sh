#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome to the core Kubernetes specific lab setup script."

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
echo "This script will:"
echo "  Download the step certificate tools and create a self signed root cert"
echo "  Gather basic information (your initials)"
echo "  Create a compartment for you to work in"
echo "  Create and configure a database for you to use"
echo "  Create a Kubernetes cluster"
echo "  Create an auth token to use when talking to OCIR"
echo "  Create OCIR repos for the storefront and stockmanager microservices"
echo "  Build, package and upload to OCIR the images you will use"
echo "  Setup YAML files for image locations"
echo ""
echo "This script can in most cases automatically apply a sensible default answer to questions (for example the name used"
echo "for the database or the compartment location). Alternatively you can specify answers manually which would let you"
echo "chose customise names and locations."
echo "Note that for some inputs (e.g. entering your initials) it is not possible to make an automatic guess, in those cases"
echo "you will still be prompted for input."

read -p "Do you want to use the automatic defaults ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   export AUTO_CONFIRM=false
   export PARALLEL_SETUP=false
else
   export AUTO_CONFIRM=true
   echo "This script can perform certain setup operations in parallel, doing so will speed"
   echo "the overall process up but you won't see the detailed output unless you look at the"
   echo "log files (they are in $HOME/setup-logs)"
   echo "If you want to follow their progress as script is running (don't interrupt it!) you'll"
   echo "need to do something like"
   echo 'tail -f $HOME/setup-logs/<log name>'
   echo "in a separate cloud shell while this script is running"
   read -p "Do you want to run the setup in parallel where possible ?" REPLY
   if [[ ! $REPLY =~ ^[Yy]$ ]]
   then
     export PARALLEL_SETUP=false
   else
     export PARALLEL_SETUP=true
   fi
fi

SAVED_PWD=`pwd`

cd $MODULES_DIR

bash ./core-kubernetes-setup-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Core kubernetes setup module returned an error, unable to continue"
  exit $RESP
fi

exit 0