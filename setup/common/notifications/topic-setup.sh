#!/bin/bash -f

if [ $# -lt 1 ]
then
  echo "The topic setup script requires one argument:"
  echo "the name of the topic to to create"
  echo "Optional args"
  echo "Description of the topic"
  exit 1
fi

TOPIC_NAME=$1
if [ $# -gt 1 ]
then
  TOPIC_DESCRIPTION=$2
else
  TOPIC_DESCRIPTION="Not provided"
fi
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

if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

TOPIC_NAME_CAPS=`bash ../settings/to-valid-name.sh $TOPIC_NAME`
TOPIC_OCID_NAME=TOPIC_"$TOPIC_NAME_CAPS"_OCID
TOPIC_REUSED_NAME=TOPIC_"$TOPIC_NAME_CAPS"_REUSED

if [ -z "${!TOPIC_REUSED_NAME}" ]
then
  echo "No reuse info for topic $TOPIC_NAME"
else
  echo "This script has already setup the topic $TOPIC_NAME"
  exit 0
fi

# try to locate an existing instance that's in the deleting state
TOPIC_DELEING_OCID=`oci ons topic list --compartment-id $COMPARTMENT_OCID --name "$TOPIC_NAME" | jq -j '.data[] | select (."lifecycle-state" == "DELETING") | ."topic-id"'`
if [ -z "$TOPIC_DELEING_OCID" ]
then
  echo "Topic $TOPIC_NAME does exist in a deleting state continuing"
else 
  echo "Topic $TOPIC_NAME is in a deleting state, unable to continue"
  exit 3
fi

TOPIC_OCID=`oci ons topic list --compartment-id $COMPARTMENT_OCID --name "$TOPIC_NAME" | jq -j '.data[] | select (."lifecycle-state" != "DELETING") | ."topic-id"'`

if [ -z "$TOPIC_OCID" ]
then
  echo "Topic $TOPIC_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Topic $TOPIC_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Topic $TOPIC_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the topic and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing topic $TOPIC_NAME"
    echo "$TOPIC_OCID_NAME=$TOPIC_OCID" >> $SETTINGS
    echo "$TOPIC_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating topic $TOPIC_NAME"
TOPIC_OCID=`oci ons topic create --compartment-id $COMPARTMENT_OCID --name "$TOPIC_NAME" --description "$TOPIC_DESCRIPTION" | jq -e '.data."topic-id"'`
if [ -z "$TOPIC_OCID" ]
then
  echo "Topic $TOPIC_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created topic $TOPIC_NAME"
echo "$TOPIC_OCID_NAME=$TOPIC_OCID" >> $SETTINGS
echo "$TOPIC_REUSED_NAME=false" >> $SETTINGS