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

echo "Welcome to the Helidon development specific lab destroy script."
echo "For the questions where you are asked for y/n input only enter lower case y or n (yes or no are not understood)"
read -p "Are you running in a free trial account, or in an account where you have full administrator rights (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an administrator or in a free trial account this script cannot automatically"
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

read -p "Do you want to proceed (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting this script"
  exit 0 
fi

echo "This script can in most cases automatically apply a sensible default answer to questions in line with the intent."
echo "to destroy the setup."

read -p "Do you want to use the automatic defaults (y/n) ?" REPLY
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