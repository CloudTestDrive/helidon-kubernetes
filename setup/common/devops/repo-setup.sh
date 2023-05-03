#!/bin/bash -f

REQUIRED_ARGS_COUNT=2
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the devops repo to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "Optional args"
  echo "  Description of the repo"
  echo "Note"
  echo " This script only creates hosted repositories, not mirrored ones"
  exit 1
fi

DEVOPS_REPO_NAME=$1
DEVOPS_PROJECT_NAME=$2
# In the future then maybe we will allow this to be selected
DEVOPS_REPO_TYPE="HOSTED"
if [ $# -ge 3 ]
then
  DEVOPS_REPO_DESCRIPTION="$3"
else
  DEVOPS_REPO_DESCRIPTION="Not provided"
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

# get the possible reuse and OCID for the devops repo itself
echo "Getting var names for devops repo $DEVOPS_REPO_NAME"
DEVOPS_REPO_OCID_NAME=`bash ./get-repo-ocid-name.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_REPO_REUSED_NAME=`bash ./get-repo-reused-name.sh $DEVOPS_REPO_NAME $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_REPO_REUSED_NAME}" ]
then
  echo "No reuse info for devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
  exit 0
fi

DEVOPS_REPO_NON_ACTIVE_OCID=`oci devops repository list --name "$DEVOPS_REPO_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$DEVOPS_REPO_NON_ACTIVE_OCID" ]
then
  echo "Devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME does not exist in a non active state"
else
  echo "Devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME exists in a non active state, cannot proceed"
  exit 10
fi
DEVOPS_REPO_OCID=`oci devops repository list --name "$DEVOPS_REPO_NAME" --project-id $DEVOPS_PROJECT_OCID --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_REPO_OCID" ]
then
  echo "Devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops repo $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops repo $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_REPO_OCID_NAME=$DEVOPS_REPO_OCID" >> $SETTINGS
    echo "$DEVOPS_REPO_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_REPO_OCID=`oci devops repository create --name "$DEVOPS_REPO_NAME" --project-id "$DEVOPS_PROJECT_OCID" --repository-type "$DEVOPS_REPO_TYPE" --description "$DEVOPS_REPO_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_REPO_OCID" ]
then
  echo "devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops repo $DEVOPS_REPO_NAME in project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_REPO_OCID_NAME=$DEVOPS_REPO_OCID" >> $SETTINGS
echo "$DEVOPS_REPO_REUSED_NAME=false" >> $SETTINGS