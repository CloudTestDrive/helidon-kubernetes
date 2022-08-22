#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi


bash ./delete-from-saved-settings.sh IMAGES_READY

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "$SCRIPT_NAME  will run the required commands to destroy the container images setup for the lab"
echo "It will only destroy repositories and tokens created by these scripts, if you reused an existing resource"
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
fi

echo "Let's clean your container image environment up"
bash container-image-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the container images, cannot continue"
  exit $RESP
fi
bash ocir-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the OCIR repos, cannot continue"
  exit $RESP
 fi

bash auth-token-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the auth tokens cannot continue"
  exit $RESP
fi
