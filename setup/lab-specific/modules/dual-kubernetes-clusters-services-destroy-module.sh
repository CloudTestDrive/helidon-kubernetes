#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings, cannot continue"
  exit 10
fi
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
SAVED_PWD=`pwd`

cd $KUBERNETES_OPTIONAL_LABS_DIR
bash ./monitoring-destroy.sh $CLUSTER_CONTEXT_NAME_ONE
bash ./monitoring-destroy.sh $CLUSTER_CONTEXT_NAME_TWO
bash ./logs-to-ooss-fluentd-dual-cluster-destroy.sh $CLUSTER_CONTEXT_NAME_ONE $CLUSTER_CONTEXT_NAME_TWO

cd $PERSISTENCE_DIR
bash ./logger-microservice-destroy.sh "$CLUSTER_CONTEXT_NAME_ONE"
bash ./logger-microservice-destroy.sh "$CLUSTER_CONTEXT_NAME_TWO"

cd $KUBERNETES_LABS_DIR

bash ./kubernetes-services-destroy.sh $CLUSTER_CONTEXT_NAME_ONE
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services destroy in cluster $CLUSTER_CONTEXT_NAME_ONE returned an error, unable to continue"
  exit $RESP
fi

bash ./kubernetes-services-destroy.sh $CLUSTER_CONTEXT_NAME_TWO
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services destroy in cluster $CLUSTER_CONTEXT_NAME_TWO returned an error, unable to continue"
  exit $RESP
fi



exit 0