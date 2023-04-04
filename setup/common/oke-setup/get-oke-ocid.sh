#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one arguments, the name of the OKE cluster to process"
  exit -1
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  source $SETTINGS
else 
  echo "No existing settings cannot continue"
  exit 10
fi

OKE_NAME=$1
OKE_OCID_NAME=`bash ./get-okd-ocid-name.sh $OKE_NAME`
OKE_OCID="${!OKE_OCID_NAME}"
if [ -z "$OKE_OCID" ]
then
  echo "Cannot locate OCID for OKE cluster $OKE_NAME"
  exit 1
fi
echo $DEVOPS_REPO_OCID