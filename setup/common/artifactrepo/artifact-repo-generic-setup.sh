#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument:"
  echo "the name of the artifact to to create"
  echo "Optional args"
  echo "  Immutable flag (true or false) defaults to false"
  echo "  Description of the artifact repo"
  exit 1
fi

ARTIFACT_REPO_NAME=$1
if [ $# -ge 2 ]
then
  ARTIFACT_REPO_IMMUTABLE="$2"
else
  ARTIFACT_REPO_IMMUTABLE="true"
fi

if [ "$ARTIFACT_REPO_IMMUTABLE" != "true"  && "$ARTIFACT_REPO_IMMUTABLE" != "true" ]
then
  echo "You have provided an immutable flag that is not either true or false, you specified $ARTIFACT_REPO_IMMUTABLE Unable to continue"
  exit 3
fi
if [ $# -ge 3 ]
then
  ARTIFACT_REPO_DESCRIPTION="$3"
else
  ARTIFACT_REPO_DESCRIPTION="Not provided"
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
echo "Getting var names for devops project $ARTIFACT_REPO_NAME"
ARTIFACT_REPO_OCID_NAME=`bash ./get-artifact-repo-ocid-name.sh $ARTIFACT_REPO_NAME`
ARTIFACT_REPO_REUSED_NAME=`bash ./get-artifact-repo-reused-name.sh $ARTIFACT_REPO_NAME`
if [ -z "${!ARTIFACT_REPO_REUSED_NAME}" ]
then
  echo "No reuse info for artifact repo $ARTIFACT_REPO_NAME"
else
  echo "This script has already setup the artifact repo $ARTIFACT_REPO_NAME"
  exit 0
fi

ARTIFACT_REPO_NON_ACTIVE_OCID=`oci artifacts repository list --compartment-id $COMPARTMENT_OCID --display-name "$ARTIFACT_REPO_NAME" --all | jq -j '.data.items[] | select (."lifecycle-state" != "ACTIVE") | ."id"'`
if [ -z "$ARTIFACT_REPO_NON_ACTIVE_OCID" ]
then
  echo "Artifact repo $ARTIFACT_REPO_NAME does not exist in a non active state"
else
  echo "Artifact repo $ARTIFACT_REPO_NAME exists in a non active state, cannot proceed"
  exit 10
fi
ARTIFACT_REPO_OCID=`oci artifacts repository list --compartment-id $COMPARTMENT_OCID --display-name "$ARTIFACT_REPO_NAME" --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "Artifact repo $ARTIFACT_REPO_NAME does not exist, creating it"
else
  ARTIFACT_REPO_OCID=`oci artifacts repository list --compartment-id $COMPARTMENT_OCID --display-name "$ARTIFACT_REPO_NAME" --is-immutable $ARTIFACT_REPO_IMMUTABLE --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`
  if [ -z "$ARTIFACT_REPO_OCID" ]
  then
    echo "Artifact repo $ARTIFACT_REPO_NAME exists and is active but is not in the immutable setting of $ARTIFACT_REPO_IMMUTABLE that you specified, cannot continue"
    exit 4
  fi
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Artifact repo $ARTIFACT_REPO_NAME exists with immutable setting of $ARTIFACT_REPO_IMMUTABLE, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops project $ARTIFACT_REPO_NAME exists with immutable setting of $ARTIFACT_REPO_IMMUTABLE, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the artifact repository and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing repository $ARTIFACT_REPO_NAME"
    echo "$ARTIFACT_REPO_OCID_NAME=$ARTIFACT_REPO_OCID" >> $SETTINGS
    echo "$ARTIFACT_REPO_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating artifact repository $ARTIFACT_REPO_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
ARTIFACT_REPO_OCID=`oci artifacts repository create-generic-repository --compartment-id $COMPARTMENT_OCID --display-name "$ARTIFACT_REPO_NAME" --is-immutable "$ARTIFACT_REPO_IMMUTABLE" --description "$ARTIFACT_REPO_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$ARTIFACT_REPO_OCID" ]
then
  echo "Artifacts generic repo $ARTIFACT_REPO_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created artifact generic repo $ARTIFACT_REPO_NAME"
echo "$ARTIFACT_REPO_OCID_NAME=$ARTIFACT_REPO_OCID" >> $SETTINGS
echo "$ARTIFACT_REPO_REUSED_NAME=false" >> $SETTINGS