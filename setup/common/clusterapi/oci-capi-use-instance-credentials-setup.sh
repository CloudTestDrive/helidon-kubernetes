#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Using context name $CLUSTER_CONTEXT_NAME for the management cluster"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME for the management cluster"
fi

echo "Running setup of instance credentials based core capi service"
bash ./oci-capi-dynamic-group-setup.sh
bash ./oci-capi-ccm-policies-setup.sh
bash ./download-clusterctl.sh
bash ./oci-capi-provisioner-setup.sh  $CLUSTER_CONTEXT_NAME