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

bash ./check-minimum-resources.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Check minimum resources (base resources) returned an error, unable to continue"
  exit $RESP
fi

bash ./core-environment-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "core environment setup returned an error, unable to continue"
  exit $RESP
fi

# The following can run in parallel


if [ "$PARALLEL_SETUP" = "true" ]
then
  DB_LOG=$LOGS_DIR/dbSetupLogs.txt
  echo "Creating the database in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the database creation in the log file at $DB_LOG"
  bash database-setup.sh 2>&1 > $DB_LOG &
else
  bash database-setup.sh
  RESP=$?
  if [ $RESP -ne 0 ]
  then
    echo "Failure creating the database, cannot continue"
    echo "Please review the output and rerun the script"
    exit $RESP
  fi
fi
SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup

if [ "$PARALLEL_SETUP" = "true" ]
then
  OKE_LOG_ONE=$LOGS_DIR/okeSetupLogs-$CLUSTER_CONTEXT_NAME_ONE.txt
  echo "Creating the OKE cluster called $CLUSTER_CONTEXT_NAME_ONE in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the OKE cluster $CLUSTER_CONTEXT_NAME_ONE creation in the log file at $OKE_LOG_ONE"
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME_ONE 2>&1 > $OKE_LOG_ONE &
else
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME_ONE
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "oke cluster $CLUSTER_CONTEXT_NAME_ONE setup returned an error, unable to continue"
    exit $RESP
  fi
fi
if [ "$PARALLEL_SETUP" = "true" ]
then
  OKE_LOG_TWO=$LOGS_DIR/okeSetupLogs-$CLUSTER_CONTEXT_NAME_TWO.txt
  echo "Creating the OKE cluster called $CLUSTER_CONTEXT_NAME_TWO in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the OKE cluster $CLUSTER_CONTEXT_NAME_TWO creation in the log file at $OKE_LOG_TWO"
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME_TWO 2>&1 > $OKE_LOG_TWO &
else
  bash ./oke-cluster-setup.sh $CLUSTER_CONTEXT_NAME_TWO
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "oke cluster two setup returned an error, unable to continue"
    exit $RESP
  fi
fi
cd $SAVED_PRE_OKE

if [ "$PARALLEL_SETUP" = "true" ]
then
  IMAGES_LOG=$LOGS_DIR/imagesSetupLogs.txt
  echo "Creating the container images in the background, please ensure they have been created before the microservices"
  echo "You can see the progress of the container image creation in the log file at $IMAGES_LOG"
  bash ./image-environment-setup.sh 2>&1 > $IMAGES_LOG &
else
  bash ./image-environment-setup.sh
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "image environment returned an error, unable to continue"
    exit $RESP
  fi
fi

# if we are doing things in parallel we need to wait for them to finish before proceeding

cd $DR_LABS_DIR

if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-dual-clusters.sh $CLUSTER_CONTEXT_NAME_ONE $CLUSTER_CONTEXT_NAME_TWO
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Problem setting up core services and dual clusters, cannot continue"
    exit $RESP
  fi
fi

cd $SAVED_PRE_OKE


# once we have the database and other details we can configure the repo

# we need the info in the settings file
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading configured settings"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No configured settings, cannot continue"
    exit 10
fi
cd $KUBERNETES_LABS_DIR
bash ./configure-downloaded-git-repo.sh $USER_INITIALS

exit 0