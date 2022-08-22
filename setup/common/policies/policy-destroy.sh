#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument"
  echo "the name of the policy to destroy"
  exit 1
fi

POLICY_NAME=$1
POLICY_NAME_CAPS=`bash ../settings/to-valid-name.sh $POLICY_NAME`
POLICY_OCID_NAME=POLICY_"$POLICY_NAME_CAPS"_OCID
POLICY_REUSED_NAME=POLICY_"$POLICY_NAME_CAPS"_REUSED

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



if [ -z "${!POLICY_REUSED_NAME}" ]
then
  echo "$SCRIPT_NAME No reuse information, cannot safely proceed with delete of policy $POLICY_NAME"
  exit 0
fi

if [ "${!POLICY_REUSED_NAME}" = true ]
then
  echo "$SCRIPT_NAME Cannot delete a policy ( $POLICY_NAME ) not created by these scripts"
  exit 0
fi

if [ -z "${!POLICY_OCID_NAME}" ]
then
  echo "$SCRIPT_NAME No OCID information for policy namnes $POLICY_NAME, perhaps it's already been deleted ? cannot proceed"
  exit 0
fi

echo "Getting home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

echo "Deleting policy $POLICY_NAME"
oci iam policy delete --policy-id "${!POLICY_OCID_NAME}" --force --region $OCI_HOME_REGION
bash ../delete-from-saved-settings.sh $POLICY_OCID_NAME
bash ../delete-from-saved-settings.sh $POLICY_REUSED_NAME

