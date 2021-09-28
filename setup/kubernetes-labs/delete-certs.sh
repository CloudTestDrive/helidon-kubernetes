#!/bin/bash -f
source $HOME/clusterSettings
if [ $# -eq 0 ]
  then
    echo 'About to remove all tls*.crt and tls*.key files'
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo 'Removing all tls*.crt and tls*.key files'
fi
echo key files
find $HOME/helidon-kubernetes -name tls\*.key -print -exec rm '{}' \;
echo crt files
find $HOME/helidon-kubernetes -name tls\*.crt -print -exec rm '{}' \;