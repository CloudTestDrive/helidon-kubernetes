#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the current External IP address of the ingress controler service"
    exit -1 
fi

echo checking https://store.$1.nip.io/store/stocklevel for a 200 response

resp=""
WAIT_LOOP_LIMIT=60
checkcounter=0
while [ -z "$resp" ] ; do
  let checkcounter="$checkcounter+1"
  echo "Waiting for services to start, test $checkcounter"
  resp=$(curl -i -X GET -u jack:password -k -s https://store.$1.nip.io/store/stocklevel | grep "200 OK")
  if [ -z "$resp" ] 
  then
    if [ "$checkcounter" = "$WAIT_LOOP_LIMIT" ]
    then
      echo "Hit the wait limit, sorry, cannot continue"
      exit 1
    fi
    sleep 10
  fi
done