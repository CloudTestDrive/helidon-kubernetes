#!/bin/bash -f

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

if [ -z "$OPENSEARCH_POLICIES_CONFIGURED" ]
then
  echo "OpenSearch policies not configured, setting up"
else
  echo "OpenSearch policies already configured"
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

cd ../../common/policies


# Get the comparment name
COMPARTMENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data.name'`

FINAL_RESP="0"
bash ./policy-by-text-setup.sh "$USER_INITIALS"OpenSearchPolicy "[\"Allow service opensearch to manage vnics in compartment $COMPARTMENT_NAME\", \"Allow service opensearch to use subnets in compartment $COMPARTMENT_NAME\", \"Allow service opensearch to use network-security-groups in compartment $COMPARTMENT_NAME\", \"Allow service opensearch to manage vcns in compartment $COMPARTMENT_NAME\"]" "This policy allows the dynamic group of code repo resources resources to create trigger the build process"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up policy "$USER_INITIALS"OpenSearchPolicy response is $RESP"
  FINAL_RESP=$RESP
fi
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/policies
  bash ../delete-from-saved-settings.sh OPENSEARCH_POLICIES_CONFIGURED
  echo OPENSEARCH_POLICIES_CONFIGURED=true >> $SETTINGS
  exit $FINAL_RESP
fi