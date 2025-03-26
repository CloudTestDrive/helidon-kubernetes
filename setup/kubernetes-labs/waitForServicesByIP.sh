#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the current External IP address of the ingress controler service"
    exit -1 
fi
EXTERNAL_IP=$1

echo "checking https://store.$EXTERNAL_IP.nip.io/store/stocklevel for a 200 response"

OK_RESP=""
WAIT_LOOP_LIMIT=60
CHECK_COUNTER=0
while [ -z "$OK_RESP" ] ; do
  let CHECK_COUNTER="$CHECK_COUNTER+1"
  echo -n "Waiting for services to start on https://store.$EXTERNAL_IP.nip.io/store/stocklevel, test $CHECK_COUNTER"
  RESP=`curl -i -X GET -u jack:password -k -s https://store.$EXTERNAL_IP.nip.io/store/stocklevel | grep "HTTP/"`
  echo "response is $RESP"
  OK_RESP=`echo $RESP | grep "200 OK"`
  if [ -z "$OK_RESP" ] 
  then
    if [ "$CHECK_COUNTER" = "$WAIT_LOOP_LIMIT" ]
    then
      echo "Hit the wait limit, sorry, cannot continue"
      exit 1
    fi
    sleep 10
  fi
done