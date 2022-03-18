#!/bin/bash -f

if [ $# -lt 1 ]
then
  echo "The user group setup script requires one argument"
  echo "the name of the dynamic group to destroy"
  exit 1
fi

GROUP_NAME=$1
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_OCID
GROUP_REUSED_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_REUSED

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS



if [ -z "${!GROUP_REUSED_NAME}" ]
then
  echo "No reuse information, , perhaps it's already been removed ? Cannot safely proceed with deleting group"
  exit 0
fi

if [ "${!GROUP_REUSED_NAME}" = true ]
then
  echo "Cannot delete a dynamic group not created by these scripts, please delete the matching rule by hand"
  exit 0
fi

if [ -z "${!GROUP_OCID_NAME}" ]
then
  echo "No dynamic group OCID information, cannot proceed"
  exit 0
fi

echo "Deleting dynamic group $GROUP_NAME"
oci iam dynamic-group delete --dynamic-group-id "${!GROUP_OCID_NAME}" --force
bash ../delete-from-saved-settings.sh $GROUP_OCID_NAME
bash ../delete-from-saved-settings.sh $GROUP_REUSED_NAME

