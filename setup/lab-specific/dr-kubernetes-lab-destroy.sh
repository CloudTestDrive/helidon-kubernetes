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
if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome to the Optional Kubernetes specific lab destroy script."
echo "For the questions where you are asked for y/n input only enter lower case y or n (yes or no are not understood)"
echo "This script will destroy the Kubernetes services environment:"
echo "  It will attempt to delete any namespaces setup in the optional labs (monitoring, logging and linkerd)"
echo "  Delete the microservices images and repos in OCIR"
echo "  Delete the auth token created to access OCIR (it will not logout of docker though)"
echo "  Reset the Kubernetes cluster to it's defult state by deleting the microservices and related objects"
echo "  Reset the Kubernetes configuration files (ingress rules, config info etc.)"
echo "  Terminate the Kubernetes cluster"
echo "  Terminate the database and destroy test data"
echo "  Attempt to remove your working a compartment (this will fail if it contains resources you've created)"
echo "  Remove gathered basic information such as your initials"
echo "  Remove the downloaded step certificate manager and certificates it's generated"
echo "At completion this will have removed the resources created by the setup scripts, however any resources that"
echo "you configured manually (for example your devops project) will remain"

read -p "Do you want to proceed (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting this script"
  exit 0 
fi
read -p "Do you want to use the automatic defaults (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   export AUTO_CONFIRM=false
else
   export AUTO_CONFIRM=true
fi

SAVED_PWD=`pwd`

cd $MODULES_DIR

bash ./dual-kubernetes-clusters-services-destroy-module.sh one two
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Dual cluster Kubernetes services destroy module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD
cd $MODULES_DIR

bash ./dual-kubernetes-clusters-destroy-module.sh one two
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Core Kubernetes dual cluster destroy module returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD



exit 0