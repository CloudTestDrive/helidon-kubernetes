#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo You must provide the IP address used to create the certificate files
    exist 1
fi
ip=$1
if [ $# -eq 1 ]
  then
    echo 'About to remove all tls*$ip.crt and tls*$ip.key files'
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo 'Removing all tls*$ip.crt and tls*$ip.key files'
fi
echo key files
find $HOME/helidon-kubernetes -name tls\*$ip.key -print -exec rm '{}' \;
echo crt files
find $HOME/helidon-kubernetes -name tls\*$ip.crt -print -exec rm '{}' \;