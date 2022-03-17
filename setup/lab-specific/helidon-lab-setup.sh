#!/bin/bash -f

if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi

echo "Welcome the the helidon development specific lab setup script."
read -p "Are you running in a free trial account, or in an account where you have full administrator rights ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "Unfortunately if you are not an adminitrator or in a free trial account this script cannot automatically"
  echo "configure your environment. You can probabaly still run the labs however. Please follow the instructions"
  echo "in the lab documentation to manually configure your environment"
  exit 1
fi
echo "This script will:"
echo "  Gather basic information (your initials)"
echo "  Create a compartment for you to work in"
echo "  Create and configure a database for you to use"
echo "You will still need to setup your virtual machine manually however as this script cannot"
echo "pull an image from the marketplace for you."

echo "This script can in most cases automatically apply a sensible default answer to questions (for example the name used"
echo "for the database or the compartment location). Alternatively you can specify answers manually which would let you"
echo "Customise names and locations."
echo "Note that for some inputs (e.g. entering your initials) it is not possible to make an automaic guess, in those cases"
echo "you will still be prompted for input."

read -p "Do you want to use the automatic defaults ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   export AUTO_CONFRM=false
else
   export AUTO_CONFRM=true
fi

SAVED_PWD=`pwd`

cd $COMMON_DIR

bash ./core-environment-setup.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "Core setup returned an error, unable to continue"
  exit $RECP
fi
exit 0