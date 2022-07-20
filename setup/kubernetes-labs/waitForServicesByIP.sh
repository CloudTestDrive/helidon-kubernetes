#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the current External IP address of the ingress controler service"
    exit -1 
fi
EXTERNAL_IP=$1

echo "checking https://store.$EXTERNAL_IP.nip.io/store/stocklevel for a 200 response"

RESP=""
WAIT_LOOP_LIMIT=60
CHECK_COUNTER=0
while [ -z "$RESP" ] ; do
  let CHECK_COUNTER="$CHECK_COUNTER+1"
  echo "Waiting for services to start, test $CHECK_COUNTER"
  resp=$(curl -i -X GET -u jack:password -k -s https://store.$EXTERNAL_IP.nip.io/store/stocklevel | grep "200 OK")
  if [ -z "$RESP" ] 
  then
    if [ "$CHECK_COUNTER" = "$WAIT_LOOP_LIMIT" ]
    then
      echo "Hit the wait limit, sorry, cannot continue"
      exit 1
    fi
    sleep 10
  fi
done