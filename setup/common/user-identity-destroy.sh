#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings
    source $SETTINGS
  else 
    echo No existing settings, cannot continue
fi

bash ./delete-from-saved-settings.sh USER_OCID