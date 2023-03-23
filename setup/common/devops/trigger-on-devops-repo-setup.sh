#!/bin/bash -f

if [ $# -lt 4 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires three arguments:"
  echo "the name of the devops trigger to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "the name of the devops code repo to monitor"
  echo "the name of the devops code repo branch to monitor"
  echo "the name of the devops build pipeline to call"
  echo "Optional args"
  echo "  Description of the trigger"
  exit 1
fi

DEVOPS_TRIGGER_NAME=$1
DEVOPS_PROJECT_NAME=$2
DEVOPS_REPO_NAME=$3
DEVOPS_REPO_BRANCH_NAME=$4
DEVOPS_BUILD_PIPELINE_NAME=$5
if [ $# -ge 6 ]
then
  DEVOPS_TRIGGER_DESCRIPTION="$6"
else
  DEVOPS_TRIGGER_DESCRIPTION="Not provided"
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

# get the possible OCID for the devops project itself
echo "Getting ocid for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID=`bash ./get-project-ocid.sh $DEVOPS_PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "get project ocid returned an error, unable to continue"
  exit $RESP
fi
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "No ocid found for devops project $DEVOPS_PROJECT_NAME cannot continue. Has the project been created with the project-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops project $DEVOPS_PROJECT_NAME continuing"
fi

# get the possible OCID for the devops repo
echo "Getting ocid for devops repo $DEVOPS_REPO_NAME in project  $DEVOPS_PROJECT_NAME"
DEVOPS_REPO_OCID=`bash ./get-repo-ocid.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "get repo ocid returned an error, unable to continue"
  exit $RESP
fi
DEVOPS_REPO_OCID="${!DEVOPS_REPO_OCID_NAME}"
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "No ocid found for devops repo $DEVOPS_REPO_NAME in project  $DEVOPS_PROJECT_NAME cannot continue. Has the repo been created with the repo-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops repo $DEVOPS_REPO_NAME in project  $DEVOPS_PROJECT_NAME continuing"
fi


# get the possible OCID for the devops repo
echo "Getting ocid for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project  $DEVOPS_PROJECT_NAME"
DEVOPS_BUILD_PIPELINE_OCID=`bash ./get-build-pipeline-ocid.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "get build pipeline ocid returned an error, unable to continue"
  exit $RESP
fi
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "No ocid found for devops buiild pipeline $DEVOPS_BUILD_PIPELINE_NAME in project  $DEVOPS_PROJECT_NAME cannot continue. Has the repo been created with the repo-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project  $DEVOPS_PROJECT_NAME continuing"
fi
# get the possible reuse and OCID for the devops trigger itself
echo "Getting var names for devops trigger $DEVOPS_TRIGGER_NAME"
DEVOPS_TRIGGER_OCID_NAME=`bash ./get-trigger-ocid-name.sh $DEVOPS_TRIGGER_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_TRIGGER_REUSED_NAME=`bash ./get-trigger-reused-name.sh $DEVOPS_TRIGGER_NAME $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_PROJECT_REUSED_NAME}" ]
then
  echo "No reuse info for devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
  exit 0
fi
DEVOPS_TRIGGER_OCID=`oci devops trigger list --display-name "$DEVOPS_TRIGGER_NAME" --compartment-id $COMPARTMENT_OCID  --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_TRIGGER_OCID" ]
then
  echo "Devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops trigger $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops trigger $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_TRIGGER_OCID_NAME=$DEVOPS_TRIGGER_OCID" >> $SETTINGS
    echo "$DEVOPS_TRIGGER_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
TRIGGER_ACTIONS="{\"buildPipelineId\": \"$DEVOPS_BUILD_PIPELINE_OCID\", \"filter\":{\"events\": [\"PUSH\"],\"include\": {\"head-ref\": \"$DEVOPS_REPO_BRANCH_NAME\"},\"trigger-source\": \"DEVOPS_CODE_REPOSITORY\"}, \"type\": \"TRIGGER_BUILD_PIPELINE\"}"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_TRIGGER_OCID=`oci devops trigger create-devops-code-repo-trigger --actions "$TRIGGER_ACTIONS" --display-name "$DEVOPS_TRIGGER_NAME" --project-id "$DEVOPS_PROJECT_OCID" --description "$DEVOPS_TRIGGER_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_TRIGGER_OCID" ]
then
  echo "devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops trigger $DEVOPS_TRIGGER_NAME in project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_TRIGGER_OCID_NAME=$DEVOPS_TRIGGER_OCID" >> $SETTINGS
echo "$DEVOPS_TRIGGER_REUSED_NAME=false" >> $SETTINGS