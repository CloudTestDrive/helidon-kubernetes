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
K8S_LOGGING_APPLIED_NAME_ONE=`bash ../common/settings/to-valid-name.sh  "K8S_LOGGING_APPLIED_"$CLUSTER_CONTEXT_NAME_ONE`
K8S_LOGGING_APPLIED_NAME_TWO=`bash ../common/settings/to-valid-name.sh  "K8S_LOGGING_APPLIED_"$CLUSTER_CONTEXT_NAME_TWO`


echo "Waiting for core services and both clusters to be available." 
export WAIT_LOOP_COUNT=180

bash ../common/wait-for-service-availability.sh $K8S_LOGGING_APPLIED_NAME_ONE $K8S_LOGGING_APPLIED_NAME_TWO

RESP=$?

if [ $RESP -ne 0 ]
then
  echo "One of both of the tasks $K8S_LOGGING_APPLIED_NAME_ONE $K8S_LOGGING_APPLIED_NAME_TWO did not start within $WAIT_LOOP_COUNT test loops"
  echo "Cannot continue"
  exit $RESP
fi
exit 0