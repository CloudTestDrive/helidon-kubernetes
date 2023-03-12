#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments:"
  echo "the name of the devops deploy pipeline to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "Optional args"
  echo "  Description of the deploy pipeline"
  exit 1
fi

DEVOPS_DEPLOPY_PIPELINE_NAME=$1
DEVOPS_PROJECT_NAME=$2
if [ $# -ge 3 ]
then
  DEVOPS_DEPLOPY_PIPELINE_DESCRIPTION="$3"
else
  DEVOPS_DEPLOPY_PIPELINE_DESCRIPTION="Not provided"
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

# get the possible reuse and OCID for the devops deploy pipeline itself
echo "Getting var names for devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME"
DEVOPS_DEPLOPY_PIPELINE_OCID_NAME=`bash ./get-deploy-pipeline-ocid-name.sh $DEVOPS_DEPLOPY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOPY_PIPELINE_REUSED_NAME=`bash ./get-deploy-pipeline-reused-name.sh $DEVOPS_DEPLOPY_PIPELINE_NAME $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_PROJECT_REUSED_NAME}" ]
then
  echo "No reuse info for devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
  exit 0
fi

DEVOPS_DEPLOPY_PIPELINE_NON_ACTIVE_OCID=`oci devops deploy-pipeline list --display-name "$DEVOPS_DEPLOPY_PIPELINE_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$DEVOPS_DEPLOPY_PIPELINE_NON_ACTIVE_OCID" ]
then
  echo "Devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME does not exist in a non active state"
else
  echo "Devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists in a non active state, cannot proceed"
  exit 10
fi
DEVOPS_DEPLOPY_PIPELINE_OCID=`oci devops deploy-pipeline list --display-name "$DEVOPS_DEPLOPY_PIPELINE_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_DEPLOPY_PIPELINE_OCID" ]
then
  echo "Devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops deploy pipeline $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops deploy pipeline $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_DEPLOPY_PIPELINE_OCID_NAME=$DEVOPS_DEPLOPY_PIPELINE_OCID" >> $SETTINGS
    echo "$DEVOPS_DEPLOPY_PIPELINE_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_DEPLOPY_PIPELINE_OCID=`oci devops deploy-pipeline create --display-name "$DEVOPS_DEPLOPY_PIPELINE_NAME" --project-id "$DEVOPS_PROJECT_OCID" --description "$DEVOPS_DEPLOPY_PIPELINE_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_DEPLOPY_PIPELINE_OCID" ]
then
  echo "devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops deploy pipeline $DEVOPS_DEPLOPY_PIPELINE_NAME in project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_DEPLOPY_PIPELINE_OCID_NAME=$DEVOPS_DEPLOPY_PIPELINE_OCID" >> $SETTINGS
echo "$DEVOPS_DEPLOPY_PIPELINE_REUSED_NAME=false" >> $SETTINGS