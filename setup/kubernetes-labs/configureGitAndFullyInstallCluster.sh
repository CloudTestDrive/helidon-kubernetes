#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the name of your department - in lower case and only a-z, e.g. tims and optional the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
contextname=one
department=$1
if [ $# -eq 1 ]
  then
    echo setting up config in downloaded git repo using $department as the department name $contextname as the kubernetes context and $HOME/Wallet.zip as the DB wallet file.
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    if [ $# -eq 2 ]
    then
      contextname=$2
      echo "Setting up config in downloaded git repo using $department as the department name, $contextname as the cluster context name (which must exist in the kubeconf) and $HOME/Wallet.zip as the DB wallet file."
      read -p "Proceed ? " -n 1 -r
      echo    # (optional) move to a new line
      if [[ ! $REPLY =~ ^[Yy]$ ]]
        then
          echo OK, exiting
          exit 1
      fi
    else
      echo "Skipping confirmation, will use $department as the department name, $contextname as the cluster context name"
    fi
fi

contextMatch=`kubectl config get-contexts | awk '{print $2}'  | grep $contextname | wc -l`

if [ $contextMatch -eq 0 ]
  then
    echo context $contextname not found, unable to continue
    exit 2
  else
    echo Context $contextname found
fi

startContext=`bash get-current-context.sh`
echo Saving current context of $startContext and switching to $contextname

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/switch-context.sh $contextname skip
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/configure-downloaded-git-repo.sh $department skip

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/fullyInstallCluster.sh $department skip

echo returning to previous context of $startContext
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/switch-context.sh $startContext skip