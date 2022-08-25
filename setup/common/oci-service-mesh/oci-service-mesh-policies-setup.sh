#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z "$OCI_OSOK_SERVICE_MESH_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "OCI OSOK Service Mesh policies not configured, setting up"
else
  echo "OCI OSOK Service Mesh policies already configured"
  exit 0
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "$SCRIPT_NAME Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "$SCRIPT_NAME Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi
SAVED_DIR=`pwd`


DG_NAME=`bash oci-service-mesh-get-dynamic-group-name.sh $USER_INITIALS`
SM_POLICY_NAME=`bash oci-service-mesh-get-service-mesh-policy-name.sh $USER_INITIALS`
OBSERVABILITY_POLICY_NAME=`bash oci-service-mesh-get-observability-policy-name.sh $USER_INITIALS`


cd ../policies

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`
FINAL_RESP="0"
# Setup the policies, for now we're going to use a policy that basically is just wide optn, we can restrict this later
#SM_POLICY_RULE="[\"Allow dynamic-group $DG_NAME to manage service-mesh-family in compartment $COMPARTMENT_NAME\",  \"Allow dynamic-group $DG_NAME to manage autonomous-database-family in compartment $COMPARTMENT_NAME\",  \"Allow dynamic-group $DG_NAME to manage mysql-family in compartment $COMPARTMENT_NAME\",  \"Allow dynamic-group $DG_NAME to manage stream-family in compartment $COMPARTMENT_NAME\"]" 
#
#echo "Creating service mesh core policies"
#bash ./policy-by-text-setup.sh "$SM_POLICY_NAME" "$SM_POLICY_RULE" "This policy allows the dynamic group of OKE Service operator resources resources to create and manage the service mesh"
#RESP=$?
#if [ "$RESP" -ne 0 ]
#then
#  echo "Problem setting up policy $SM_POLICY_NAME response is $RESP"
#  FINAL_RESP=$RESP
#fi
#
#OBSERVABILITY_POLICY_RULE="[\"Allow dynamic-group $DG_NAME to use metrics in compartment $COMPARTMENT_NAME\",  \"Allow dynamic-group $DG_NAME to use log-content in compartment $COMPARTMENT_NAME\"]" 
#
#echo "Creating service mesh observability policies"
#bash ./policy-by-text-setup.sh "$OBSERVABILITY_POLICY_NAME" "$OBSERVABILITY_POLICY_RULE" "This policy allows the dynamic group of OKE Service operator resources resources to create and manage logging and monitoring resources"
#RESP=$?
#if [ "$RESP" -ne 0 ]
#then
#  echo "Problem setting up policy $OBSERVABILITY_POLICY_NAME response is $RESP"
#  FINAL_RESP=$RESP
#fi
SM_POLICY_RULE="[\"Allow dynamic-group $DG_NAME to manage all-resources in compartment $COMPARTMENT_NAME\", \"Allow group Administrators to manage all-resources in compartment $COMPARTMENT_NAME\"]" 

echo "Creating service mesh core policies"
bash ./policy-by-text-setup.sh "$SM_POLICY_NAME" "$SM_POLICY_RULE" "This policy allows the dynamic group resources resources to do everything"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy $SM_POLICY_NAME response is $RESP"
  FINAL_RESP=$RESP
fi
cd $SAVED_DIR
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/policies
  bash ../delete-from-saved-settings.sh OCI_OSOK_SERVICE_MESH_POLICIES_CONFIGURED
  echo OCI_OSOK_SERVICE_MESH_POLICIES_CONFIGURED=true >> $SETTINGS
  exit $FINAL_RESP
fi