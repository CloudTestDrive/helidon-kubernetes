#!/bin/bash -f
SCRIPT_NAME=`basename $0`

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

if [ -z "$CLUSTER_API_CCM_POLICIES_CONFIGURED" ]
then
  echo "Cluster API ccm policies not configured, setting up"
else
  echo "Cluster API ccm policies already configured"
  exit 0
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi
SAVED_DIR=`pwd`

cd ../policies

DG_NAME="$USER_INITIALS"ClusterAPIDynamicGroup
# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

POLICY_RULE="[ \"ALLOW dynamic-group $DG_NAME to manage drgs in compartment $COMPARTMENT_NAME \", \"ALLOW dynamic-group $DG_NAME to manage virtual-network-family in compartment $COMPARTMENT_NAME \",  \"ALLOW dynamic-group $DG_NAME to manage load-balancers in compartment $COMPARTMENT_NAME \", \"ALLOW dynamic-group $DG_NAME to manage instance-family in compartment $COMPARTMENT_NAME \", \"ALLOW dynamic-group $DG_NAME to manage tags in compartment $COMPARTMENT_NAME \", \"ALLOW dynamic-group $DG_NAME to manage volume-family in compartment $COMPARTMENT_NAME\"]" 

FINAL_RESP="0"
bash ./policy-by-text-setup.sh "$USER_INITIALS"ClusterAPICCMRepoPolicy "$POLICY_RULE" "This policy allows the dynamic group of code repo resources resources to create trigger the build process"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy "$USER_INITIALS"DevOpsCodeRepoPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
cd $SAVED_DIR
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/policies
  bash ../delete-from-saved-settings.sh CLUSTER_API_CCM_POLICIES_CONFIGURED
  echo CLUSTER_API_CCM_POLICIES_CONFIGURED=true >> $SETTINGS
  exit $FINAL_RESP
fi