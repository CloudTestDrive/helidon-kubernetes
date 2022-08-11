#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "the initial name of the key to, this will be updated to include your user initials"
  exit 1
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
VAULT_KEY_NAME=$1

if [ -z "$USER_INITIALS" ]
then
  echo "$SCRIPT_NAME Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 11
fi
echo  "$USER_INITIALS""$VAULT_KEY_NAME"