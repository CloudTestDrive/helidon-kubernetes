#!/bin/bash
currentContext=`bash get-current-context.sh`
if [ $# -eq 0 ]
  then
    echo "Missing arguments, you must provide the name of your department - in lower case and only a-z, e.g. tims"
    exit -1
    
fi
department=$1
if [ $# -eq 1 ]
  then
    echo setting up config in downloaded git repo using $department as the department name $currentContext is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file.
    read -p "Proceed (y/n) ?"
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping fully install cluster confirmation, will setup using  $department as the department name $currentContext is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file"
fi

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/installBaseElements.sh skip

source $HOME/clusterSettings.$currentContext

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/executeRunStack.sh $department $EXTERNAL_IP skip