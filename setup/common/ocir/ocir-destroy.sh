#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME requires one argument"
  echo "the name of the OCIR repo to destroy"
  exit 1
fi

OCIR_REPO_NAME=$1
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

# get the possible reuse and OCID for the repo itself
echo "Getting var names for ocir repo $OCIR_REPO_NAME"
OCIR_REPO_OCID_NAME=`bash ./get-ocir-ocid-name.sh $OCIR_REPO_NAME`
OCIR_REPO_REUSED_NAME=`bash ./get-ocir-reused-name.sh $OCIR_REPO_NAME`

if [ -z "${!OCIR_REPO_REUSED_NAME}" ]
then
  echo "No reuse information for OCIR repo $OCIR_REPO_NAME , perhaps it's already been removed ? Cannot safely proceed with deleting OCIR repo"
  exit 0
fi

if [ "${!OCIR_REPO_REUSED_NAME}" = true ]
then
  echo "Cannot delete an OCIR repo not created by these scripts, please delete the $OCIR_REPO_NAME repo by hand"
  exit 0
fi

OCIR_REPO_OCID="${!OCIR_REPO_OCID_NAME}"
if [ -z "${!OCIR_REPO_OCID}" ]
then
  echo "No OCIR repo $OCIR_REPO_NAME OCID information, cannot proceed"
  exit 0
fi

echo "Deleting OCIR repo $OCIR_REPO_NAME"

oci artifacts container repository delete --repository-id  $OCIR_REPO_OCID --force  --wait-for-state "DELETED" --wait-interval-seconds 10
bash ../delete-from-saved-settings.sh $OCIR_REPO_OCID_NAME
bash ../delete-from-saved-settings.sh $OCIR_REPO_REUSED_NAME

