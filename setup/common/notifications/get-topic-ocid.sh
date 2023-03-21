#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the topic to process"
  exit -1
fi
TOPIC_NAME=$1
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi

TOPIC_OCID_NAME=`bash get-topic-ocid-name.sh $TOPIC_NAME`
TOPIC_OCID="${!TOPIC_OCID_NAME}"
if [ -z "$TOPIC_OCID" ]
then
  echo "Cannot locate OCID for topic $TOPIC_NAME"
  exit 1
fi
echo $TOPIC_OCID