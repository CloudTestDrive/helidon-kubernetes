#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments:"
  echo "the name of the devops project to to create"
  echo "the name of the notifications topic (which must have"
  echo "  already been created with the topic-setup.sh script)"
  echo "Optional args"
  echo "Description of the devops project"
  exit 1
fi

DEVOPS_PROJECT_NAME=$1
TOPIC_NAME=$2
if [ $# -ge 3 ]
then
  DEVOPS_PROJECT_DESCRIPTION="$3"
else
  DEVOPS_PROJECT_DESCRIPTION="Not provided"
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

# get the possible reuse and OCID for the devops project itself
echo "Getting var names for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID_NAME=`bash ./get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_REUSED_NAME=`bash ./get-project-reused-name.sh $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_PROJECT_REUSED_NAME}" ]
then
  echo "No reuse info for devops project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops project $DEVOPS_PROJECT_NAME"
  exit 0
fi

# get the OCID var name of our topic
echo "Getting var names for topic $TOPIC_NAME"
SAVED_DIR=`pwd`
cd ../notifications
TOPIC_OCID_NAME=`bash ./get-topic-ocid-name.sh $TOPIC_NAME`
cd $SAVED_DIR

# get the OCID of the topic if set, if not error
TOPIC_OCID="${!TOPIC_OCID_NAME}"
if [ -z "$TOPIC_OCID" ]
then
  echo "Cannot locate the OCID in settings for topic $TOPIC_NAME, has it already been created ?"
  echo "If not then the topic-setup.sh script will need to be run"
  exit -5
fi

DEVOPS_PROJECT_NON_ACTIVE_OCID=`oci devops project list --compartment-id $COMPARTMENT_OCID --name "$DEVOPS_PROJECT_NAME" --all | jq -j '.data.items[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$DEVOPS_PROJECT_NON_ACTIVE_OCID" ]
then
  echo "Devops project $DEVOPS_PROJECT_NAME does not exist in a non active state"
else
  echo "Devops project $DEVOPS_PROJECT_NAME exist in a non active state, cannot proceed"
  exit 10
fi
DEVOPS_PROJECT_OCID=`oci devops project list --compartment-id $COMPARTMENT_OCID --name "$DEVOPS_PROJECT_NAME" --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "Devops project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops project and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_PROJECT_OCID_NAME=$DEVOPS_PROJECT_OCID" >> $SETTINGS
    echo "$DEVOPS_PROJECT_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_PROJECT_OCID=`oci devops project create --compartment-id $COMPARTMENT_OCID --name "$DEVOPS_PROJECT_NAME" --description "$DEVOPS_PROJECT_DESCRIPTION" --notification-config "{\"topicId\":\"$TOPIC_OCID\"}" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "devops project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_PROJECT_OCID_NAME=$DEVOPS_PROJECT_OCID" >> $SETTINGS
echo "$DEVOPS_PROJECT_REUSED_NAME=false" >> $SETTINGS