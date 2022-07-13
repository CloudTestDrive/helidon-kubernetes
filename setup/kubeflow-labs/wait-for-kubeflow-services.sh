#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

OKE_OCID_NAME=`bash ../common/setting/to-valud-name.sh OKE_OCID_$CLUSTER_CONTEXT_NAME`

echo "Waiting for core services to be available." 
export WAIT_LOOP_COUNT=180

bash ../common/wait-for-service-availability.sh $OKE_OCID_NAME

RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of more of the services DB_OCID $OKE_OCID_NAME IMAGES_READY did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0