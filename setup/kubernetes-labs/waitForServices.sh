#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the current External IP address of the ingress controler service"
    exit -1 
fi

echo checking https://store.$1.nip.io/store/stocklevel for a 200 response

ip=""
while [ -z "$ip" ] ; do
  echo "Waiting for services to start"
  ip=$(curl -i -X GET -u jack:password -k -s https://store.$1.nip.io/store/stocklevel | grep "200 OK")
  [ -z "$ip" ] && sleep 10
done