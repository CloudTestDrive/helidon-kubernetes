#!/bin/bash -f

if [ -z "$PARALLEL_SETUP" ]
then
  export PARALLEL_SETUP=false
fi

LOGS_DIR=$HOME/setup-logs

SETUP_DIR=$HOME/helidon-kubernetes/setup
MODULES_DIR=$SETUP_DIR/lab-specific/modules

SAVED_PWD=`pwd`
cd $OPEN_SEARCH_DIR
bash ./opensearch-policy-setup.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Opensearch policy setup returned an error, unable to continue"
  exit $RESP
fi

cd $SAVED_PWD
exit 0