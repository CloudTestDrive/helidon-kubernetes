#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo You must provide the IP address used to create the certificate files
    exist 1
fi
EXTERNAL_IP=$1
if [ $# -eq 1 ]
  then
    echo 'About to remove all tls*$EXTERNAL_IP.crt and tls*$EXTERNAL_IP.key files'
    read -p "Proceed (y/n) ?"
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo 'Removing all tls*$EXTERNAL_IP.crt and tls*$EXTERNAL_IP.key files'
fi
echo key files
find $HOME/helidon-kubernetes -name tls\*$EXTERNAL_IP.key -print -exec rm '{}' \;
echo crt files
find $HOME/helidon-kubernetes -name tls\*$EXTERNAL_IP.crt -print -exec rm '{}' \;