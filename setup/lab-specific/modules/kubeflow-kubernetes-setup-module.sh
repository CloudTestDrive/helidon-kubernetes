#!/bin/bash -f

if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi

LOGS_DIR=$HOME/setup-logs
if [ "$PARALLEL_SETUP" = "true" ]
then
  mkdir -p $LOGS_DIR
fi

# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

cd $COMMON_DIR

bash ./download-step.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Downloading step returned an error, unable to continue"
  exit $RESP
fi

# this needs to be modularised on a per-lab basis
#bash ./check-minimum-resources.sh
#RESP=$?
#if [ "$RESP" -ne 0 ]
#then
#  echo "Check minimum resources (base resources) returned an error, unable to continue"
#  exit $RESP
#fi

bash ./core-environment-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "core environment setup returned an error, unable to continue"
  exit $RESP
fi

# The following can run in parallel
KUBEFLOW_CLUSTER_NAME=kubeflow


SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup
if [ "$PARALLEL_SETUP" = "true" ]
then
  OKE_LOG=$LOGS_DIR/okeSetupLogs.txt
  echo "Creating the OKE cluster in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the OKE cluster creation in the log file at $OKE_LOG"
  bash ./oke-cluster-setup.sh $KUBEFLOW_CLUSTER_NAME 2>&1 > $OKE_LOG &
else
  bash ./oke-cluster-setup.sh $KUBEFLOW_CLUSTER_NAME
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "oke cluster setup returned an error, unable to continue"
    exit $RESP
  fi
fi

cd $SAVED_PRE_OKE

# if we are doing things in parallel we need to wait for them to finish before proceeding

cd $KUBEFLOW_LABS

if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-kubeflow-services.sh $KUBEFLOW_CLUSTER_NAME
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Problem setting up core services, cannot continue"
    exit $RESP
  fi
fi



exit 0