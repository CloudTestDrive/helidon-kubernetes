#!/bin/bash
source $HOME/clusterSettings
if [ $# -eq 0 ]
  then
    echo About to destroy existing instalation in $NAMESPACE, and remove the ingress controller and dashboard
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
fi
if [ $# -eq 1 ]
    then
    echo "Skipping confirmation, destroying existing instalation in $$NAMESPACE, and remove the ingress controller and dashboard"
fi

bash $HOME/helidon-kubernetes/setup/kubernetes-labs/teardownStack.sh $NAMESPACE skip
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/removeBaseElements.sh skip