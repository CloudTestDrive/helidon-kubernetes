#!/bin/bash -f

SCRIPT_NAME=`basename $0`

CLUSTER_CONTEXT_NAME_ONE=one
CLUSTER_CONTEXT_NAME_TWO=two

if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME_ONE=$1
  CLUSTER_CONTEXT_NAME_TWO=$2
  echo "$SCRIPT_NAME using provided cluster names of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
else
  echo "$SCRIPT_NAME using default cluster names of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
fi

KUBERNETES_CLUSTER_TYPE_NAME_ONE=`bash ../common/settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME_ONE`
KUBERNETES_CLUSTER_TYPE_NAME_TWO=`bash ../common/settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME_TWO`


echo "Waiting for core services and both clusters to be available." 
export WAIT_LOOP_COUNT=180

bash ../common/wait-for-service-availability.sh DB_OCID $KUBERNETES_CLUSTER_TYPE_NAME_ONE $KUBERNETES_CLUSTER_TYPE_NAME_TWO IMAGES_READY

RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of more of the services DB_OCID $KUBERNETES_CLUSTER_TYPE_NAME_ONE $KUBERNETES_CLUSTER_TYPE_NAME_TWO IMAGES_READY did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0