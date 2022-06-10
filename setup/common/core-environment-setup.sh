#!/bin/bash -f

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
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
  echo "replacing <parents ocid> with the OCID of the Parent compartment you foind"
  echo "You may need to create the $HOME/hk8sLabsSettings file."
  echo "Having done this the compartment-setup.sh script will look for (or create) compartments within that parent"
  echo "Once you have done this the run the following commands in order in the region you want to run the lab"
  echo "in the $HOME/helidon-kubernetes/setup/common directory"
  echo "bash initials-setup.sh"
  echo "bash user-identity-setup.sh"
  echo "bash compartment-setup.sh"
  exit 1
else
  echo "Thank you for confirming you are in a free trial, let's set your basic environment up"
fi
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
