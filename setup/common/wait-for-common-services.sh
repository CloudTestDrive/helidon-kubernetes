#!/bin/bash -f

if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi
KUBERNETES_CLUSTER_TYPE_NAME=`bash settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME`

echo "Waiting for core services to be available." 
export WAIT_LOOP_COUNT=180

bash ./wait-for-service-availability.sh DB_OCID $KUBERNETES_CLUSTER_TYPE_NAME IMAGES_READY

RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of more of the services DB_OCID $KUBERNETES_CLUSTER_TYPE_NAME IMAGES_READY did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0