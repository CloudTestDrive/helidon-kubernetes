#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument:"
  echo "the name of the log group to to create"
  echo "Optional args"
  echo "Description of the log group"
  exit 1
fi

LOG_GROUP_NAME=$1
if [ $# -gt 1 ]
then
  LOG_GROUP_DESCRIPTION="$2"
else
  LOG_GROUP_DESCRIPTION="Not provided"
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

echo "Getting var names for log group $LOG_GROUP_NAME"
LOG_GROUP_OCID_NAME=`bash ./get-log-group-ocid-name.sh $LOG_GROUP_NAME`
LOG_GROUP_REUSED_NAME=`bash ./get-log-group-reused-name.sh $LOG_GROUP_NAME`

if [ -z "${!LOG_GROUP_REUSED_NAME}" ]
then
  echo "No reuse info for log group $LOG_GROUP_NAME"
else
  echo "This script has already setup the log group $LOG_GROUP_NAME"
  exit 0
fi

LOG_GROUP_OCID=`oci logging log-group list --compartment-id $COMPARTMENT_OCID --display-name "$LOG_GROUP_NAME" | jq -j '.data[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$LOG_GROUP_OCID" ]
then
  echo "Log group $LOG_GROUP_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Log group $LOG_GROUP_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Log group $LOG_GROUP_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the log group and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing log group $LOG_GROUP_NAME"
    echo "$LOG_GROUP_OCID_NAME=$LOG_GROUP_OCID" >> $SETTINGS
    echo "$LOG_GROUP_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating log group $LOG_GROUP_NAME"
LOG_GROUP_OCID=`oci logging log-group create --compartment-id $COMPARTMENT_OCID --display-name "$LOG_GROUP_NAME" --description "$LOG_GROUP_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$LOG_GROUP_OCID" ]
then
  echo "Log group $LOG_GROUP_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created log group $LOG_GROUP_NAME"
echo "$LOG_GROUP_OCID_NAME=$LOG_GROUP_OCID" >> $SETTINGS
echo "$LOG_GROUP_REUSED_NAME=false" >> $SETTINGS