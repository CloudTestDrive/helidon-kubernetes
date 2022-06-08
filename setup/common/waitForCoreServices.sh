#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

OKE_OCID_NAME=OKE_OCID_$CLUSTER_CONTEXT_NAME

./waitForServiceAvailability ATPDB_OCID $OKE_OCID_NAME, IMAGES_READY