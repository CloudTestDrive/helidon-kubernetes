#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings, cannot continue"
  exit 10
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome to the DevOps specific lab destroy script."
echo "For the questions where you are asked for y/n input only enter lower case y or n (yes or no are not understood)"

read -p "Are you running in a free trial account, or in an account where you have full administrator rights (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an administrator or in a free trial account this script cannot automatically"
  echo "configure your environment. You can probabaly still run the labs however. Please follow the instructions"
  echo "in the lab documentation to manually configure your environment"
  exit 1
fi

echo "It will remove the DevOps services lab speciifc content by :"
echo "  Delete the policies based on the dynamic groups which allow Devops services to run builds and update your Kubernetes cluster"
echo "  Delete the dynamic groups used to identify various dev ops service elements"
echo "  Delete the ssh key to use when connecting to the OCI code repo (note that the $HOME/.ssh/config file will not be modified)"
echo "  Schedule deletion of the Vault secrets, the master signing key and the Vault"
echo ""
echo "This script will destroy the Kubernetes services environment:"
echo "  Delete the microservices images and repos in OCIR"
echo "  Delete the auth token created to access OCIR (it will not logout of docker though)"
echo "  Reset the Kubernetes cluster to it's defult state by deleting the microservices and related objects"
echo "  Reset the Kubernetes configfuration files (ingress rules, config info etc.)"
echo "  Terminate the Kubernrtes cluster"
echo "  Terminate the database and destroy test data"
echo "  Attempt to remove your working a compartment (this will fail if it contains resources you've created)"
echo "  Remove gathered basic information such as your initials"
echo "  Remove the downloaded step certificate manager and certificats it's generated"
echo "At completion this will have removed the resources created by the setup scripts, however any resources that"
echo "you configured outside the devops-lab-setup.sh script (for example your devops project will remain."

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

bash ./devops-destroy-module.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps module destroy returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD

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