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

contextMatch=`kubectl config get-contexts --output=name | grep -w $contextname`

if [ -z $contextMatch ]
  then
    echo context $contextname not found, unable to continue
    exit 2
  else
    echo Context $contextname found
fi

echo Configuring base location variables
export LAB_LOCATION=$HOME/helidon-kubernetes
export LAB_SETUP_LOCATION=$LAB_LOCATION/setup
export KUBERNETES_SETUP_LOCATION=$LAB_SETUP_LOCATION/kubernetes-labs
echo Configuring helm
bash $KUBERNETES_SETUP_LOCATION/setupHelm.sh

startContext=`bash get-current-context.sh`
echo Saving current context of $startContext and switching to $contextname

bash $KUBERNETES_SETUP_LOCATION/switch-context.sh $contextname skip
bash $KUBERNETES_SETUP_LOCATION/configure-downloaded-git-repo.sh $department skip

bash $KUBERNETES_SETUP_LOCATION/fullyInstallCluster.sh $department skip


echo Creating test data
source $HOME/clusterSettings.$contextname
bash $LAB_LOCATION/create-test-date.sh $ip

echo returning to previous context of $startContext
bash $KUBERNETES_SETUP_LOCATION/switch-context.sh $startContext skip