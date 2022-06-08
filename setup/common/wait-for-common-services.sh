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

echo "Waiting for core services to be available." 

bash ./wait-for-service-availability.sh ATPDB_OCID $OKE_OCID_NAME IMAGES_READY