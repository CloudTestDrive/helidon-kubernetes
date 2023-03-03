#!/bin/bash -f

if [ $# -lt 1 ]
then
  echo "The user group setup script requires one argument"
  echo "the name of the topic to destroy"
  exit 1
fi

TOPIC_NAME=$1
TOPIC_NAME_CAPS=`bash ../settings/to-valid-name.sh $TOPIC_NAME`
TOPIC_OCID_NAME=POLICY_"$TOPIC_NAME_CAPS"_OCID
TOPIC_REUSED_NAME=POLICY_"$TOPIC_NAME_CAPS"_REUSED
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



if [ -z "${!TOPIC_REUSED_NAME}" ]
then
  echo "No reuse information, , perhaps it's already been removed ? Cannot safely proceed with deleting topic"
  exit 0
fi

if [ "${!TOPIC_REUSED_NAME}" = true ]
then
  echo "Cannot delete a topic group not created by these scripts, please delete the topic by hand"
  exit 0
fi

if [ -z "${!TOPIC_OCID_NAME}" ]
then
  echo "No topic OCID information, cannot proceed"
  exit 0
fi

TOPIC_OCID="${!TOPIC_OCID_NAME}"

echo "Deleting topic $TOPIC_NAME"

oci ons topic delete --topic-id  --force 
bash ../delete-from-saved-settings.sh $TOPIC_OCID_NAME
bash ../delete-from-saved-settings.sh $TOPIC_REUSED_NAME

