#!/bin/bash -f

if [ $# -lt 2 ]
then
  echo "The user group setup script requires one argument"
  echo "the name of the dynamic group to destroy"
  echo "the resource typoe of the dynamic group e.g. devopsbuildpipeline"
  echo "the description of the dynamic group (which needs to be quoted)"
  exit 1
fi

GROUP_NAME=$1
GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $GROUP_NAME`
GROUP_OCID_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_OCID
GROUP_REUSED_NAME=DYNAMIC_GROUP_"$GROUP_NAME_CAPS"_REUSED

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

source $SETTINGS


if [ -z "${!GROUP_OCID_NAME}" ]
then
  echo "No dynamic group OCID information, cannot proceed"
  exit 1
fi


if [ -z "${!GROUP_REUSED_NAME}" ]
then
  echo "No reuse information, cannot safely proceed with deleting group"
  exit 2
fi

if [ "${!GROUP_REUSED_NAME}" = true ]
then
  echo "Cannot delete a dynamic group not created by these scripts, please delete the matching rule by hand"
  exit 3
fi

echo "Deleting dynamic group"
oci iam dynamic-group delete --dynamic-group-id "${!GROUP_OCID_NAME}"
bash ../delete-from-saved-settings.sh $GROUP_OCID_NAME
bash ../delete-from-saved-settings.sh $GROUP_REUSED_NAME

