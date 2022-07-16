#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome to the Core Kubernetes specific lab destroy script."
echo "For the questions where you are asked for y/n input only enter lower case y or n (yes or no are not understood)"

read -p "Are you running in a free trial account, or in an account where you have full administrator rights (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an administrator or in a free trial account this script cannot automatically"
  echo "configure your environment. You can probabaly still run the labs however. Please follow the instructions"
  echo "in the lab documentation to manually configure your environment"
  exit 1
fi

echo "This script will destroy the Core Kubernetes environment:"
echo "  Delete the microservices images and repos in OCIR"
echo "  Delete the auth token created to access OCIR (it will not logout of docker though)"
echo "  Reset the Kubernetes cluster to it's defult state by deleting the microservices and related objects"
echo "  Reset the Kubernetes configuration files (ingress rules, config info etc.)"
echo "  Terminate the Kubernetes cluster"
echo "  Terminate the database and destroy test data"
echo "  Attempt to remove your working a compartment (this will fail if it contains resources you've created)"
echo "  Remove gathered basic information such as your initials"
echo "  Remove the downloaded step certificate manager and certificates it's generated"
echo "At completion this will have removed the resources created by the setup scripts, however any resources outside the"
echo "Kubernetes cluster, this means that unless you have already deleted the ingress-nginx namespace created when you"
echo "setup the ingress contrtoller (or done a helm unitnalle of the ingress controller) that the load balancer will"
echo "not be destroyed, and neither will the VCN."
echo ""
echo "Therefore if you have not released the Load balancer please stop this script, delete those and then re-run it"

read -p "Do you want to proceed (y/n) ?" REPLY
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

read -p "Do you want to use the automatic defaults (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   export AUTO_CONFIRM=false
else
   export AUTO_CONFIRM=true
fi

SAVED_PWD=`pwd`

cd $MODULES_DIR

# Try and tidy things up in the cluster
# fortunately everything uses the same ingress so only one LB which is created when the ingrss controller is creted
# so just delete the controller namespoace which will delete the LB, everything else is inside OKE so will be destroyed 
# with the cluster

kubectl delete namespace ingress-nginx --ignore-not-found=true

cd $MODULES_DIR

bash ./kubeflow-kubernetes-destroy-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubeflow Kubernetes destroy module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD



exit 0