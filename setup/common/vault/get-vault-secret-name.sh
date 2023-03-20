#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the vault setting to process"
  exit -1
fi
SETTINGS_NAME=$1
SETTINGS_NAME_VAR=`bash ../settings/to-valid-name.sh $SETTINGS_NAME`
VAULT_SECRET_NAME=$SETTINGS_NAME_VAR"_VAULT"
echo $VAULT_SECRET_NAME