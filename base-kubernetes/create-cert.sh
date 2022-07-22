#!/bin/bash
SCRIPT_NAME=`basename $0`

if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME missing arguments, you must provide:"
  echo "  1st arg External IP address of the load balancer"
  exit -1
fi
EXTERNAL_IP=$1
echo "creating tls secret using common name of store.$EXTERNAL_IP.nip.io"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls-store.key -out tls-store.crt -subj "/CN=store.$EXTERNAL_IP.nip.io/O=nginxsvc"