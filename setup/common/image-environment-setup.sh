#!/bin/bash -f


export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
echo "This script will run the required commands to setup your own images"

bash auth-token-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the auth token, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi
bash ocir-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the OCIR repos, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi
bash container-image-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the container images, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi

bash ./delete-from-saved-settings.sh IMAGES_READY
echo "IMAGES_READY=true" >> $SETTINGS
