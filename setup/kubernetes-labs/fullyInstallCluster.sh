#!/bin/bash
currentContext=`bash get-current-context.sh`
if [ $# -eq 0 ]
  then
    echo "Missing arguments, you must provide the name of your department - in lower case and only a-z, e.g. tims"
    exit -1
    
fi
department=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, setting up config in downloaded git repo using $department as the department name $currentContext is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file defaults to $REPLY"
else  
  echo "setting up config in downloaded git repo using $department as the department name $currentContext is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo :"OK, exiting"
  exit 1
else
  echo "Will setup using  $department as the department name $currentContext is the kubernetes current context name and $HOME/Wallet.zip as the DB wallet file"
fi

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/installBaseElements.sh skip

source $HOME/clusterSettings.$currentContext

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/executeRunStack.sh $department $EXTERNAL_IP skip