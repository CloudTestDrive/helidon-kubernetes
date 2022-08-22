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


if [ -z "$OCI_OSOK_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "OCI OSOK Dynamic groups not configured, setting up"
else
  echo "OCI OSOK Dynamic groups already configured"
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


# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`
SAVED_DIR=`pwd`

DG_NAME=`bash oci-service-mesh-get-dynamic-group-name.sh $USER_INITIALS`

cd ../dynamic-groups

FINAL_RESP="0"
bash ./dynamic-group-instances-in-compartment-setup.sh "$DG_NAME" "This dynamic group identifies the resource in compartment $COMPARTMENT_NAME for user $USER_INITIALS to enable the oracle service operator for Kubernetes to function"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem setting up dynamic group $$DG_NAME response is $RESP"
  FINAL_RESP=$RESP
fi
cd $SAVED_DIR

if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  # delete script is in common, we are in common/dynamic-groups
  bash ../delete-from-saved-settings.sh OCI_OSOK_DYNAMIC_GROUPS_CONFIGURED
  echo OCI_OSOK_DYNAMIC_GROUPS_CONFIGURED=true >> $SETTINGS
  exit $FINAL_RESP
fi