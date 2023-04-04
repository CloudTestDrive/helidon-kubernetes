#!/bin/bash -f

if [ $# -lt 3 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires three arguments:"
  echo "the name of the devops deploy environment to to create"
  echo "the name of the containing project (which must have"
  echo "  already been created with the project-setup.sh script)"
  echo "the name of the oke cluster (which must have been "
  echo "  already ccreated using the oke-cluster-setup.sh script)"
  echo "Optional args"
  echo "  Description of the deploy environment"
  exit 1
fi

DEVOPS_DEPLOY_ENVIRONMENT_NAME=$1
DEVOPS_PROJECT_NAME=$2
OKE_CLUSTER_NAME=$3
if [ $# -ge 4 ]
then
  DEVOPS_DEPLOY_ENVIRONMENT_DESCRIPTION="$4"
else
  DEVOPS_DEPLOY_ENVIRONMENT_DESCRIPTION="Not provided"
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


# get the possible OCID for the oke cluster
echo "Getting ocid for OKE cluster $OKE_CLUSTER_NAME"
SAVED_DIR=`pwd`
cd ../oke-setup
OKE_CLUSTER_OCID=`bash ./get-oke-ocid.sh $OKE_CLUSTER_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "get OKC lcuster ocid returned an error $OKE_CLUSTER_OCID , unable to continue"
  exit $RESP
fi
if [ -z "$OKE_CLUSTER_OCID" ]
then
  echo "No ocid found for OKE cluster $OKE_CLUSTER_NAME cannot continue. Has the oke cluster been created with the oke-cluster-setup script ?"
  exit 1
else
  echo "Located the OCID for the OKE cluster $OKE_CLUSTER_NAME continuing"
fi
cd $SAVED_DIR

# get the possible reuse and OCID for the devops trigger itself
echo "Getting var names for devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME"
DEVOPS_DEPLOY_ENVIRONMENT_OCID_NAME=`bash ./get-deploy-environment-ocid-name.sh $DEVOPS_DEPLOY_ENVIRONMENT_NAME $DEVOPS_PROJECT_NAME`
DEVOPS_DEPLOY_ENVIRONMENT_REUSED_NAME=`bash ./get-deploy-environment-reused-name.sh $DEVOPS_DEPLOY_ENVIRONMENT_NAME $DEVOPS_PROJECT_NAME`
if [ -z "${!DEVOPS_DEPLOY_ENVIRONMENT_REUSED_NAME}" ]
then
  echo "No reuse info for devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME"
else
  echo "This script has already setup the devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME"
  exit 0
fi
DEVOPS_DEPLOY_ENVIRONMENT_OCID=`oci devops deploy-environment list --display-name "$DEVOPS_DEPLOY_ENVIRONMENT_NAME" --compartment-id $COMPARTMENT_OCID  --all | jq -j '.data.items[] | select (."lifecycle-state" == "ACTIVE") | ."id"'`

if [ -z "$DEVOPS_DEPLOY_ENVIRONMENT_OCID" ]
then
  echo "Devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME does not exist, creating it"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? defaulting to $REPLY"
  else
    read -p "Devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME exists, do you want to reuse it ? (y/n) ? " REPLY  
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will need to delete the devops deploy environment $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME and recreate it by hand or with this script to continue"
    exit 1
  else
    echo "OK, will reuse existing devops deploy environment $DEVOPS_PROJECT_NAME in project $DEVOPS_PROJECT_NAME"
    echo "$DEVOPS_DEPLOY_ENVIRONMENT_OCID_NAME=$DEVOPS_DEPLOY_ENVIRONMENT_OCID" >> $SETTINGS
    echo "$DEVOPS_DEPLOY_ENVIRONMENT_REUSED_NAME=true" >> $SETTINGS
    exit 0
  fi
fi
echo "Creating devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME"
# if waiting for state this returns the work request details (that's what we are actually waiting
# on) so from there need to extract the identifier of the resource that was created as that's the actuall one we want
DEVOPS_DEPLOY_ENVIRONMENT_OCID=`oci devops deploy-environment create-oke-cluster-environment  --cluster-id $OKE_CLUSTER_OCID --display-name "$DEVOPS_DEPLOY_ENVIRONMENT_NAME" --project-id "$DEVOPS_PROJECT_OCID" --description "$DEVOPS_DEPLOY_ENVIRONMENT_DESCRIPTION" --wait-for-state "SUCCEEDED" --wait-interval-seconds 5 | jq -j '.data.resources[0].identifier'`
if [ -z "$DEVOPS_DEPLOY_ENVIRONMENT_OCID" ]
then
  echo "devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME could not be created, unable to continue"
  exit 2
fi
echo "Created devops deploy environment $DEVOPS_DEPLOY_ENVIRONMENT_NAME in project $DEVOPS_PROJECT_NAME"
echo "$DEVOPS_DEPLOY_ENVIRONMENT_OCID_NAME=$DEVOPS_DEPLOY_ENVIRONMENT_OCID" >> $SETTINGS
echo "$DEVOPS_DEPLOY_ENVIRONMENT_REUSED_NAME=false" >> $SETTINGS