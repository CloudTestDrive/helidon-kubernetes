#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome to the Optional kubernetes specific lab setup script."
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
echo "  Setup YAML files for database and image locations"
echo "  Setup Helm chart repos"
echo "  Start core Kubernetes services (Ingress contrtoller, Kubernetes dashboard)"
echo "  Create service certificates and associated secrets based on Ingress load balancer IP"
echo "  Create ingress rules, secrets and config maps based on the above info"
echo "  Start three microservcies (sotrfront, stockmanager and zipkin)"
echo "  Upload test data to the database"
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
else
   export AUTO_CONFIRM=true
fi

SAVED_PWD=`pwd`
cd $MODULES_DIR

bash ./core-kubernetes-setup-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Core Kubernetes setup module returned an error, unable to continue"
  exit $RESP
fi

exit 0
cd $SAVED_PWD

cd $MODULES_DIR

bash ./kubernetes-services-setup-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services setup module returned an error, unable to continue"
  exit $RESP
fi

exit 0