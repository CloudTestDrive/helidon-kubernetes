#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings"
fi
if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
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
LOGS_DIR=$HOME/setup-logs
if [ "$PARALLEL_SETUP" = "true" ]
then
  mkdir -p $LOGS_DIR
fi
SAVED_PWD=`pwd`

cd $KUBERNETES_LABS_DIR

if [ "$PARALLEL_SETUP" = "true" ]
then
  K8S_SERVICES_ONE_LOG=$LOGS_DIR/kubernetesServicesSetupLogs-$CLUSTER_CONTEXT_NAME_ONE.txt
  echo "Creating the services in kubernetes cluster called $CLUSTER_CONTEXT_NAME_ONE in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the kubernetes services creation in the log file at $K8S_SERVICES_ONE_LOG"
  bash ./kubernetes-services-setup.sh $CLUSTER_CONTEXT_NAME_ONE 2>&1 > $K8S_SERVICES_ONE_LOG &
else
  bash ./kubernetes-services-setup.sh $CLUSTER_CONTEXT_NAME_ONE
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Kubernetes services setup for cluster $CLUSTER_CONTEXT_NAME_ONE returned an error, unable to continue"
    exit $RESP
  fi
fi
if [ "$PARALLEL_SETUP" = "true" ]
then
  K8S_SERVICES_TWO_LOG=$LOGS_DIR/kubernetesServicesSetupLogs-$CLUSTER_CONTEXT_NAME_TWO.txt
  echo "Creating the services in kubernetes cluster called $CLUSTER_CONTEXT_NAME_TWO in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the kubernetes services creation in the log file at $K8S_SERVICES_TWO_LOG"
  bash ./kubernetes-services-setup.sh $CLUSTER_CONTEXT_NAME_TWO 2>&1 > $K8S_SERVICES_TWO_LOG &
else
  bash ./kubernetes-services-setup.sh $CLUSTER_CONTEXT_NAME_TWO
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Kubernetes services setup for cluster $CLUSTER_CONTEXT_NAME_TWO returned an error, unable to continue"
    exit $RESP
  fi
fi

cd $DR_LABS_DIR
if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-dual-clusters-services.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Cannot continue"
    exit $RESP
  fi
fi
cd $PERSISTENCE_DIR
# now let's enable the logging capability, this is pretty simple do won't run in parallel
if [ "$PARALLEL_SETUP" = "true" ]
then
  K8S_PERSISTENCE_ONE_LOG=$LOGS_DIR/kubernetesPersistenceSetupLogs-$CLUSTER_CONTEXT_NAME_ONE.txt
  echo "Configuring persistence example in kubernetes cluster called $CLUSTER_CONTEXT_NAME_ONE in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the kubernetes services creation in the log file at $K8S_PERSISTENCE_ONE_LOG"
  bash ./logger-microservice-setup.sh $CLUSTER_CONTEXT_NAME_ONE 2>&1 > $K8S_PERSISTENCE_ONE_LOG &
else
  bash ./logger-microservice-setup.sh $CLUSTER_CONTEXT_NAME_ONE
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Kubernetes persistence example setup for cluster $CLUSTER_CONTEXT_NAME_ONE returned an error, unable to continue"
    exit $RESP
  fi
fi
# now let's enable the logging capability, this is pretty simple do won't run in parallel
if [ "$PARALLEL_SETUP" = "true" ]
then
  K8S_PERSISTENCE_TWO_LOG=$LOGS_DIR/kubernetesPersistenceSetupLogs-$CLUSTER_CONTEXT_NAME_TWO.txt
  echo "Configuring persistence example in kubernetes cluster called $CLUSTER_CONTEXT_NAME_TWO in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the kubernetes services creation in the log file at $K8S_PERSISTENCE_TWO_LOG"
  bash ./logger-microservice-setup.sh $CLUSTER_CONTEXT_NAME_TWO 2>&1 > $K8S_PERSISTENCE_TWO_LOG &
else
  bash ./logger-microservice-setup.sh $CLUSTER_CONTEXT_NAME_TWO
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Kubernetes persistence example setup for cluster $CLUSTER_CONTEXT_NAME_TWO returned an error, unable to continue"
    exit $RESP
  fi
fi

cd $DR_LABS_DIR
if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-dual-clusters-persistence.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Cannot continue"
    exit $RESP
  fi
fi

cd $KUBERNETES_OPTIONAL_LABS_DIR
bash ./logs-to-ooss-fluentd-dual-cluster-setup.sh $CLUSTER_CONTEXT_NAME_ONE $CLUSTER_CONTEXT_NAME_TWO
bash ./monitoring-setup.sh $CLUSTER_CONTEXT_NAME_ONE
bash ./monitoring-setup.sh $CLUSTER_CONTEXT_NAME_TWO

exit 0