#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome the the DevOps specific lab setup script."
read -p "Are you running in a free trial account, or in an account where you have full administrator rights ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an adminitrator or in a free trial account this script cannot automatically"
  echo "configure your environment. You can probabaly still run the labs however. Please follow the instructions"
  echo "in the lab documentation to manually configure your environment"
  exit 1
fi
echo "This script will configure the Kubernetes services environment:"
echo "  Download the step certificate tools and create a self signed root cert"
echo "  Gather basic information (your initials)"
echo "  Create a compartment for you to work in"
echo "  Create and configure a database for you to use"
echo "  Create a Kubernertes cluster"
echo "  Create an auth token to use when talking to OCIR"
echo "  Create OCIR repos for the storefront and stockmanager microservices"
echo "  Build, package and upload to OCIR the images you will use"
echo "  Setup YAML files for database and image locations"
echo "  Setup Helm chart repos"
echo "  Start core Kubernetes services (Ingress contrtoller, Kubernetes dashboard)"
echo "  Create service certificates and associated secrets based on Ingress load balancer IP"
echo "  Create ingress rules, secrets and config maps based on the above info"
echo "  Start three microservcies (storefront, stockmanager and zipkin)"
echo "  Upload test data to the database"
echo ""
echo "It will then configure for the DevOps services labs by :"
echo "  Creating a Vault and master signing key"
echo "  Configure an ssh key to use when connecting to the OCI code repo"
echo "  Create dynamic groups to identify various dev ops service elements"
echo "  Create policies based on the dynamic groups to allow Devops services to run builds and update your Kubernetes cluster"
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

cd $SAVED_PWD

cd $MODULES_DIR

bash ./kubernetes-services-setup-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services setup module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD

cd $MODULES_DIR

bash ./devops-setup-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps module setup returned an error, unable to continue"
  exit $RESP
fi

exit 0