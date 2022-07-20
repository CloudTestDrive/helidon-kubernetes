#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo "You must provide the IP address used to create the certificate files"
    exist 1
fi
EXTERNAL_IP=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo 'Auto confirm is enabled, About to remove all tls*$EXTERNAL_IP.crt and tls*$EXTERNAL_IP.key files defaulting to '"$REPLY"  
else
  echo 'About to remove all tls*$EXTERNAL_IP.crt and tls*$EXTERNAL_IP.key files'
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo 'Removing all tls*$EXTERNAL_IP.crt and tls*$EXTERNAL_IP.key files'
fi
echo key files
find $HOME/helidon-kubernetes -name tls\*$EXTERNAL_IP.key -print -exec rm '{}' \;
echo crt files
find $HOME/helidon-kubernetes -name tls\*$EXTERNAL_IP.crt -print -exec rm '{}' \;