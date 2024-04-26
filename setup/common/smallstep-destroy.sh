#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f "$SETTINGS" ]
then
    echo "Existing settings file located, loading it"
    source $SETTINGS
else
    echo "Cannot locate the settings file, cannot continue"
    exit 1
fi

if [ -z "$SMALLSTEP_DIR" ]
then 
    echo "Small step setup was not done my these scripts, exiting"
    exit 0
else
    echo "Smallstep has already been setup by these scripts, continuing"
fi

if [ -d "$SMALLSTEP_DIR" ]
then
    rm -rf "$SMALLSTEP_DIR"
else
    echo "It looks like the smallstep directory ( $SMALLSTEP_DIR ) is nto there, continuing"
fi
bash ./delete-from-saved-settings.sh SMALLSTEP_DIR
