#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments:"
  echo "the name of the devops build pipeline to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "Optional args"
  echo "  Description of the build pipeline"
  exit 1
fi

DEVOPS_BUILD_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
if [ $# -ge 3 ]
then
  DEVOPS_BUILD_PIPELINE_DESCRIPTION="$3"
else
  DEVOPS_BUILD_PIPELINE_DESCRIPTION="Not provided"
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
echo "Getting var names for devops project $DEVOPS_PROJECT_NAME"
DEVOPS_PROJECT_OCID_NAME=`bash ./get-project-ocid-name.sh $DEVOPS_PROJECT_NAME`
DEVOPS_PROJECT_OCID="${!DEVOPS_PROJECT_OCID_NAME}"
if [ -z "$DEVOPS_PROJECT_OCID" ]
then
  echo "No ocid found for devops project $DEVOPS_PROJECT_NAME cannot continue. Has the project been created with the project-setup script ?"
  exit 1
else
  echo "Located the OCID for the devops project $DEVOPS_PROJECT_NAME continuing"
fi

# get the possible reuse and OCID for the devops build pipeline itself
echo "Getting var names for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME"
DEVOPS_BUILD_PIPELINE_OCID_NAME=`bash ./get-build-pipeline-ocid-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_BUILD_PIPELINE_REUSED_NAME=`bash ./get-build-pipeline-reused-name.sh $DEVOPS_BUILD_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_BUILD_PIPELINE_REUSED_NAME}" ]
then
  echo "No reuse info for devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 0
fi

DEVOPS_BUILD_PIPELINE_NON_ACTIVE_OCID=`oci devops build-pipeline list --display-name "$DEVOPS_BUILD_PIPELINE_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$DEVOPS_BUILD_PIPELINE_NON_ACTIVE_OCID" ]
then
  echo "Devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME does not exist in a non active state"
else
  echo "Devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists in a non active state, cannot proceed"
  exit 10
fi
DEVOPS_BUILD_PIPELINE_OCID=`oci devops build-pipeline list --display-name "$DEVOPS_BUILD_PIPELINE_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "Devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops build pipeline $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops build pipeline $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_BUILD_PIPELINE_OCID_NAME=$DEVOPS_BUILD_PIPELINE_OCID" >> $SETTINGS
    echo "$DEVOPS_BUILD_PIPELINE_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_BUILD_PIPELINE_OCID=`oci devops build-pipeline create --display-name "$DEVOPS_BUILD_PIPELINE_NAME" --project-id "$DEVOPS_PROJECT_OCID" --description "$DEVOPS_BUILD_PIPELINE_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_BUILD_PIPELINE_OCID" ]
then
  echo "devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops build pipeline $DEVOPS_BUILD_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_BUILD_PIPELINE_OCID_NAME=$DEVOPS_BUILD_PIPELINE_OCID" >> $SETTINGS
echo "$DEVOPS_BUILD_PIPELINE_REUSED_NAME=false" >> $SETTINGS