#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

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


SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup
if [ "$PARALLEL_SETUP" = "true" ]
then
  OKE_LOG=$LOGS_DIR/okeSetupLogs-$CLUSTER_CONTEXT_NAME.txt
  echo "Creating the OKE cluster in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the OKE cluster creation in the log file at $OKE_LOG"
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME 2>&1 > $OKE_LOG &
else
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "oke cluster setup returned an error, unable to continue"
    exit $RESP
  fi
fi

cd $SAVED_PRE_OKE

# if we are doing things in parallel we need to wait for them to finish before proceeding

cd $COMMON_DIR
if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-single-cluster-services.sh $CLUSTER_CONTEXT_NAME
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Problem setting up core services, cannot continue"
    exit $RESP
  fi
fi


cd $KUBEFLOW_LABS

exit 0