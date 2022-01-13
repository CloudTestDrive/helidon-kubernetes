#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

if [ -z $OCIR_REUSED ]
then
  echo No reuse information for OCIR cannot safely continue, you will have to destroy it manually
  exit 1
fi

if [ $OCIR_REUSED = true ]
then
  echo You have been using an OCIR repo that was not created by these scripts, you will need to destroy the repo by hand
  echo Removing OCIR saved values from $SETTINGS 
  bash ./delete-from-saved-settings.sh OCIR_OCID
  bash ./delete-from-saved-settings.sh OCIR_REUSED
  bash ./delete-from-saved-settings.sh OCIR_LOCATION
  exit 2
fi

echo Destroying repo
oci artifacts container repository delete --repository-id $OCIR_OCID --force

echo Removing OCIR saved values from $SETTINGS 
bash ./delete-from-saved-settings.sh OCIR_OCID
bash ./delete-from-saved-settings.sh OCIR_REUSED
bash ./delete-from-saved-settings.sh OCIR_LOCATION

echo You are still logged into docker for OCIR services in $OCIR_LOCATION
echo If you with to logout from that execute the command 
echo docker logout $OCIR_LOCATION