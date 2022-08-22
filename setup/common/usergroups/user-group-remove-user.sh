#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument, the name of the group "
  echo "It will then remove the currently defined user (in the USER_OCID) to that group"
  exit 1
fi

GROUP_NAME=$1
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=GROUP_"$GROUP_NAME_CAPS"_OCID


export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS


if [ -z "$USER_OCID" ]
then
  echo "$SCRIPT_NAME Cannot locate the users OCID, have you run the user-identity-setup.sh script ?"
  exit 1
fi

if [ -z "$USER_TYPE" ]
then
  echo "$SCRIPT_NAME Cannot locate the users type, have you run the user-identity-setup.sh script ?"
  exit 2
fi

if [ -z "${!GROUP_OCID_NAME}" ]
then
  echo "$SCRIPT_NAME Cannot find the saved OCID for group $GROUP_NAME"
  exit 3
fi

USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'` 

if [ "$USER_TYPE" != "local" ]
then
  echo "Sorry, user $USERNAME is not a local user and can't be removed from a local group"
  echo "You will need to use the federated identity to remove the user from the locally"
  echo "mapped group"
  exit 4
fi

echo "Removing user $USERNAME from group $GROUP_NAME"

oci iam group remove-user --user-id $USER_OCID --group-id "${!GROUP_OCID_NAME}" --force
