#!/bin/bash -f
REQUIRED_ARGS_COUNT=1
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires 1 arguments"
  echo "The duration of the wait in seconds"
  exit -1
fi

WAIT_DURATION=$1

echo "{\"waitDuration\":\"PT""$WAIT_DURATION""S\", \"waitType\":\"ABSOLUTE_WAIT\"}"