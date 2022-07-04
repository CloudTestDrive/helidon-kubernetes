#!/bin/bash -f

if [ $# -lt 4 ]
then
  echo "The policy setup script requires four arguments:"
  echo "the name of the policy to create"
  echo "the type of policy e.g. group or dynamic-group"
  echo "The subject of the polidy c.c. tgDevopsGroup"
  echo "the description of the dynamic group (which needs to be quoted if it's multiple words)"
  exit 1
fi

POLICY_NAME=$1
POLICY_TYPE=$2
POLICY_SUBJECT=$3
POLICY_DESCRIPTION=$4
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

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi


# look for reuse info on the group, if so it's already there

if [ -z "${!POLICY_REUSED_NAME}" ]
then
  echo "No reuse info for policy $POLICY_NAME"
else
  echo "This script has already setup the policy $POLICY_NAME"
  exit 0
fi

# Get the comparment name
COMPARTMENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data.name'`

POLICY_RULE="[ \"ALLOW $POLICY_TYPE $POLICY_SUBJECT to manage all-resources in compartment $COMPARTMENT_NAME \"]" 

bash ./policy-by-text-setup.sh "$POLICY_NAME" "$POLICY_RULE" "$POLICY_DESCRIPTION"
RESP=$?
exit $RESP