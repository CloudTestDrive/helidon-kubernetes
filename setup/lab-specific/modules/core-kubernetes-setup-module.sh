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
  bash database-setup.sh >2&1 > $DB_LOG &
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

if [ "$PARALLEL_SETUP" = "true" ]
then
  OKE_LOG=$LOGS_DIR/okeSetupLogs.txt
  echo "Creating the OKE cluster in the background, please ensure it has been created before running any service against it"
  echo "You can see the progress of the OKE cluster creation in the log file at $OKE_LOG"
  bash ./kubernetes-setup.sh >2&1 > $OKE_LOG &
else
  bash ./kubernetes-setup.sh
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "kubernetes cluster setup returned an error, unable to continue"
    exit $RESP
  fi
fi

if [ "$PARALLEL_SETUP" = "true" ]
then
  IMAGES_LOG=$LOGS_DIR/imagesSetupLogs.txt
  echo "Creating the container images in the background, please ensure they have been created before the microservices"
  echo "You can see the progress of the container image creation in the log file at $IMAGES_LOG"
  bash ./image-environment-setup.sh >2&1 > $IMAGES_LOG &
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

if [ "$PARALLEL_SETUP" = "true" ]
then
  bash ./wait-for-common-services.sh
  RESP=$?
  if [ "$RESP" -ne 0 ]
  then
    echo "Problem setting up core services, cannot continue"
    exit $RESP
  fi
fi

exit 0