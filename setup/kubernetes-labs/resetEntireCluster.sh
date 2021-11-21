#!/bin/bash

if [ $# -eq 0 ]
  then
    echo "You must provide the name of the kubernetes context to use for the tear down"
    exit 1
fi

context=$1

contextMatch=`kubectl config get-contexts --output=name  | grep -w $context `

if [ -z $contextMatch ]
  then
    echo context $context not found in Kubernetes, unable to continue
    exit 2
  else
    echo Context $context exists in Kubernetes configuration file
fi

settingsFile=$HOME/clusterSettings.$context

if [ -f $settingsFile ]
  then
    source $settingsFile
    echo Located setings, using namespace $NAMESPACE
  else 
    echo Unable to locate settings file $settingsFile cannot continue
    exit 1
fi

if [ $# -eq 1 ]
  then
    echo Using context $context About to destroy existing instalation in $NAMESPACE, and remove the ingress controller and dashboard
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else 
    echo "Skipping confirmation, Using context $context About to destroy existing instalation in $$NAMESPACE, and remove the ingress controller and dashboard"
fi

currentContext=`bash get-current-context.sh`

echo Saving current context of $currentContext and switching to $context


bash $HOME/helidon-kubernetes/setup/kubernetes-labs/switch-context.sh $context skip
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/teardownStack.sh $NAMESPACE skip
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/removeBaseElements.sh skip

echo returning to previous context of $currentContext
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/switch-context.sh $currentContext skip
