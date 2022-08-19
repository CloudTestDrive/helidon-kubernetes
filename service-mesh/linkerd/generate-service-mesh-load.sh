#!/bin/bash -f

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "Missing arguments supplied to $SCRIPT_NAME, you must provide :"
    echo " 1st arg External IP address of the ingress controller Load balancer"
    exit -1 
fi
EXTERNAL_IP=$1
i=0
while true;do
i=$[$i+1]
echo "test $i"
curl -s -k -X GET -u jack:password https://store.$EXTERNAL_IP.nip.io/store/stocklevel > /dev/null
# Do a little sleep so we don't totally overload the server
sleep $2
done