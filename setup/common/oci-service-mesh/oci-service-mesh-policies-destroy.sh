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

if [ -z "$OCI_OSOK_SERVICE_MESH_POLICIES_CONFIGURED" ]
then
  echo "$SCRIPT_NAME OCI OSOK Service Mesh policies not configured, unable to proceed"
  exit 1
else
  echo "OCI OSOK Service Mesh policies configured, will remove them"
fi
if [ -z $USER_INITIALS ]
then
  echo "$SCRIPT_NAME Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi
SM_POLICY_NAME=`bash oci-service-mesh-get-service-mesh-policy-name.sh $USER_INITIALS`
OBSERVABILITY_POLICY_NAME=`bash oci-service-mesh-get-observability-policy-name.sh $USER_INITIALS`

SAVED_DIR=`pwd`
cd ../policies
FINAL_RESP="0"
bash ./policy-destroy.sh "$SM_POLICY_NAME"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem destroying policy $SM_POLICY_NAME response is $RESP"
  FINAL_RESP=$RESP
fi
# we setup a blanket policy for lab development this is in SM_POLICY_NAME
# the observability policy is encompased by that one, so it's not setup
# and we can skip that bit
#bash ./policy-destroy.sh "$OBSERVABILITY_POLICY_NAME"
#RESP=$?
#if [ "$RESP" -ne 0 ]
#then
#  FINAL_RESP=$RESP
#  echo "Problem destroying policy $OBSERVABILITY_POLICY_NAME response is $RESP"
#fi
cd $SAVED_DIR
if [ "$FINAL_RESP" -ne 0 ]
then
  exit $FINAL_RESP
else 
  bash ../delete-from-saved-settings.sh OCI_OSOK_SERVICE_MESH_POLICIES_CONFIGURED
  exit $FINAL_RESP
fi