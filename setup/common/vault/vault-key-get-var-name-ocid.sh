#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "the name of the key to convert, by convention this will have previously been prefixed with your user initials"
  exit 1
fi
VAULT_KEY_NAME=$1
bash ../settings/to-valid-name.sh  "VAULT_KEY_"$VAULT_KEY_NAME"_OCID"