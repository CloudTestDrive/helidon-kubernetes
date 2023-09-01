#!/bin/bash -f

if [ $# -lt 4 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments:"
  echo "the name of the log to create"
  echo "the name of the containing log group (which must have"
  echo "  already been created with the log-group-setup.sh script)"
  echo "the type of the service that will be logger, e.g. devops"
  echo "The ocid of the actual service instance to capture log data"
  echo "  from (of course this must exist)"
  echo "Optional"
  echo "  log category, defaults to all"
  exit 1
fi

LOG_NAME=$1
LOG_GROUP_NAME=$2
SERVICE_NAME=$3
RESOURCE_OCID=$4
LOG_CATEGORY="all"
if [ $# -ge 5 ]
then
  LOG_CATEGORY=$5
fi
# These are fixed as we are creating a service log
LOG_TYPE="SERVICE"
SOURCE_TYPE="OCISERVICE"
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


# get the possible OCID for the log grouplog groiupdevops project $LOG_GROUP_NAME"
LOG_GROUP_OCID_NAME=`bash ./get-log-group-ocid-name.sh $LOG_GROUP_NAME`
LOG_GROUP_OCID="${!LOG_GROUP_OCID_NAME}"
if [ -z "$LOG_GROUP_OCID" ]
then
  echo "No ocid found for log group $LOG_GROUP_NAME cannot continue. Has the log group been created with the log-group-setup.sh script ?"
  exit 1
else
  echo "Located the OCID for the log group $LOG_GROUP_NAME continuing"
fi

# get the possible reuse and OCID for the log  itself
echo "Getting var names for log $LOG_NAME in log group $LOG_GROUP_NAME"
LOG_OCID_NAME=`bash ./get-log-ocid-name.sh $LOG_NAME $LOG_GROUP_NAME`
LOG_REUSED_NAME=`bash ./get-log-reused-name.sh $LOG_NAME $LOG_GROUP_NAME`
if [ -z "${!LOG_REUSED_NAME}" ]
then
  echo "No reuse info for log $LOG_NAME in log group $LOG_GROUP_NAME"
else
  echo "This script has already setup the log $LOG_NAME in log group $LOG_GROUP_NAME"
  exit 0
fi

LOG_NON_ACTIVE_OCID=`oci logging log list --display-name "$LOG_NAME" --log-group-id $LOG_GROUP_OCID --all | jq -j '.data[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$LOG_NON_ACTIVE_OCID" ]
then
  echo "Log $LOG_NAME in log group $LOG_GROUP_NAME does not exist in a non active state"
else
  echo "Log $LOG_NAME in log group $LOG_GROUP_NAME exists in a non active state, cannot proceed"
  exit 10
fi
LOG_OCID=`oci logging log list --display-name "$LOG_NAME" --log-group-id $LOG_GROUP_OCID --all | jq -j '.data[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$LOG_OCID" ]
then
  echo "Log $LOG_NAME in log group $LOG_GROUP_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Log $LOG_NAME in log group $LOG_GROUP_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Log $LOG_NAME in log group $LOG_GROUP_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the Log $LOG_NAME in log group $LOG_GROUP_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing Log $LOG_NAME in log group $LOG_GROUP_NAME"
    echo "$LOG_OCID_NAME=$LOG_OCID" >> $SETTINGS
    echo "$LOG_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating log $LOG_NAME in log group $LOG_GROUP_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
LOG_CONFIG="{\"compartmentId\":\"$COMPARTMENT_OCID\", \"source\": {\"service\":\"$SERVICE_NAME\", \"resource\":\"$RESOURCE_OCID\", \"source-type\":\"$SOURCE_TYPE\", \"category\":\"$LOG_CATEGORY\"}}"
LOG_OCID=`oci logging log create --display-name "$LOG_NAME" --log-group-id "$LOG_GROUP_OCID" --log-type "$LOG_TYPE" --configuration "$LOG_CONFIG" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$LOG_OCID" ]
then
  echo "Log $LOG_NAME in log group $LOG_GROUP_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created log $LOG_NAME in log group $LOG_GROUP_NAME"
echo "$LOG_OCID_NAME=$LOG_OCID" >> $SETTINGS
echo "$LOG_REUSED_NAME=false" >> $SETTINGS