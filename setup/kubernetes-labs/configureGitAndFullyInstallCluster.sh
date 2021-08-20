#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department - in lower case and only a-z, e.g. tims"
    exit -1 
fi
if [ $# -eq 1 ]
  then
    echo setting up config in downloaded git repo using $1 as the department name and $HOME/Wallet.zip as the DB wallet file.
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping configure git and fully install cluster confirmation"
fi

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/configure-downloaded-git-repo.sh $1 skip

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/fullyInstallCLuster.sh $1 skip