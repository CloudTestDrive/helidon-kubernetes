#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "$SCRIPT_NAME  will run the required commands to destroy the core environment setup for the lab"
echo "It will only destroy resources created by these scripts, if you reused an existing resource"
echo "then those resources will not be destroyed, and neither will the compartment containing them"
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, in a destroy resources defaulting to $REPLY"
else
  read -p "Are you sure you want to destroy these resources (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, stopping script"
  exit 0
else
  echo "OK destroying resources"
  bash user-identity-destroy.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure removing the user identity cannot continue"
    exit $RESP
  fi
  bash compartment-destroy.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure destroying the compartment cannot continue"
    exit $RESP
  fi
  bash initials-destroy.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure removing the user initials cannot continue"
    exit $RESP
  fi
fi

bash ./delete-from-saved-settings.sh SETUP_REGION