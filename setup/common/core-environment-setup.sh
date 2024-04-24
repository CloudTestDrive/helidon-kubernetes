#!/bin/bash -f


export SETTINGS=$HOME/hk8sLabsSettings

if [ -f "$SETTINGS" ]
then
    echo "Existing settings file located, loading it"
    source $SETTINGS
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi

ARCH_NAME=`uname -m | tr A-Z a-z | sed -e 's/-/_/g'`
if [ "$ARCH_NAME" == "x86_64" ]
then
	echo "You are running in an x64 processor shell, this script can continue"
elif [ "$ARCH_NAME" == "aarch64" ]
then
	echo "I'm sorry, but you are running in an ARM processor shell, this script currently has some x86 specific dependencies and cannot sucesfully run to completion in an ARM environment"
	exit 11
else 
	echo "Unknown system architecture $ARCH_NAME don't know what architecture your cloud shell is cannot continue"
	exit 10
fi

echo "This script will run the required commands to setup your core environment"
echo "It assumes you are working in a free trial tenancy exclusively used by yourself"
echo "If you are not you will need to exit at the prompt and follow the lab instructions for setting up the configuration separatly"
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, free trial defaulting to $REPLY"
else
  read -p "Are you running in a free trial environment (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, you are not in a free trial tenancy exclusively used by yourself"
  echo "As shared or commercial environments often are used by many people you may want to run this lab"
  echo "in a compartment other than the default to avoid conflict, this is esiecially true if you only have"
  echo "rights to create resources in a specific compartment"
  echo "If you do not want to create a compartment to run the labs in your root compartment then you will have a choice"
  echo "You can run the lab in a compartment in the root of your tenancy, to do that specify the compartment name"
  echo "to use for the labs when you run the compartment-setup.sh script"
  echo "If you want to run the labs in a compartment that is not in the root of the tenancy (I.e. in a sub compartment)"
  echo "Then you will need to find the OCID of the PARENT of the compartment you want to use (if the compartment"
  echo "you want to use already exists within that parent you can specify it when running the compartment-setup.sh script)"
  echo "Once you have identified the OCID of the PARENT then add a line to $HOME/hk8sLabsSettings of the form "
  echo "COMPARTMENT_PARENT_OCID=<parents ocid>"
  echo "replacing <parents ocid> with the OCID of the Parent compartment you found"
  echo "You may need to create the $HOME/hk8sLabsSettings file."
  echo "Having done this the compartment-setup.sh script will look for (or create) compartments within that parent"
  echo "Once you have done this the run the following commands in order in the region you want to run the lab"
  echo "in the $HOME/helidon-kubernetes/setup/common directory"
  echo "bash initials-setup.sh"
  echo "bash user-identity-setup.sh"
  echo "bash compartment-setup.sh"
  exit 1
else
  echo "Thank you for confirming you are in a free trial"
fi
echo "Checking for previous still active configurations"
if [ -z "$SETUP_REGION" ]
then
    echo "No setup previously recorded, continuing"
else
    if [ "$SETUP_REGION" = "$OCI_REGION" ]
    then
        echo "Previous setup was run in this region, continuing"
    else
        echo "You have previously run the setup in a different region ( $SETUP_REGION ) and not destroyed that"
        echo "environment. You cannot continue as you may well corrupt your state information, and"
        echo "end up with the state looking at resources in a different region"
        exit 5
    fi
fi

# if there was a previous setup did it use the same cloud shell architecture ?
# If it didn't then bad things are likely to happen
if [ -v "$SETUP_ARCH" ]
then
    if [ "$SETUP_ARCH" = "$ARCH_NAME" ]
    then
        echo "Previous setup was done using this architecture, OK to continue"
    else
        echo "Previous setup was done using $SETUP_ARCH this is incompatible with the current arc hitecture of $ARCH_NAME you will need to destroy the previous setup and re-run this script"
        exit 10
    fi
else
    echo "No previous setup architecture value, continuing"
fi

echo "SETUP_REGION=$OCI_REGION" >> $SETTINGS
echo "SETUP_ARCH=$ARCH_NAME" >> $SETTINGS
echo "Region and architecture are good, let's set your basic environment up

bash initials-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure setting up the initials, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi
bash user-identity-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure setting up the user identity, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi
bash compartment-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the compartment, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi
