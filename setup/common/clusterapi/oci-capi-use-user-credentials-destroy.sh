#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Using context name $CLUSTER_CONTEXT_NAME for the management cluster"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME for the management cluster"
fi
echo "Running destroy of user credentials based core capi service"


bash ./oci-capi-provisioner-destroy.sh  $CLUSTER_CONTEXT_NAME
bash ./remove-clusterctl.sh
bash ./oci-capi-api-key-destroy.sh
bash ./oci-capi-ccm-policies-destroy.sh
bash ./oci-capi-dynamic-group-destroy.sh