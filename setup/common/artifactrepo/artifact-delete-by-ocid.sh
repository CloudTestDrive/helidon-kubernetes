#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument:"
  echo "the ocid of the artifact to destroy"
  exit 1
fi

ARTIFACT_OCID=$1
echo "Deleting artifact $ARTIFACT_OCID"
oci artifacts generic artifact delete --artifact-id $ARTIFACT_OCID --force  --wait-for-state "DELETED" --wait-interval-seconds 5