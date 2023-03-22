#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi

if [ -z "$DEVOPS_LAB_CODE_REPO_TRANSFERRED" ]
then
  echo "Code repo not marked as being transferred, stopping"
else
  echo "Code repo has been transferred, continuing"
fi

REPO_NAME=cloudnative-helidon-storefront
if [ -d $HOME/$REPO_NAME ]
then
  echo "The directory $REPO_NAME exists, removing it"
  rm -rf $HOME/$REPO_NAME
else
  echo "No local repo, continuing"
fi

bash ../common/delete-from-saved-settings.sh DEVOPS_LAB_CODE_REPO_TRANSFERRED