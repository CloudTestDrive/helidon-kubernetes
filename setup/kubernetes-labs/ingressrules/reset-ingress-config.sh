#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "Missing arguments supplied, you must provide the directory to process"
    exit -1 
fi

ingressdir=$1
currentcontext=`kubectl config current-context`
if [ $# -eq 1 ]
  then
    echo Removing the ingress rules yaml for context $currentcontext in $ingressdir
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping ingress rule remove confirmation"
fi

echo Removing the ingress rules yaml for context $currentcontext in $ingressdir
for ingressrulesfile in $ingressdir/ingress*Rules-$currentcontext.yaml 
do
  echo Removing ingress rules yaml $ingressrulesfile
  rm $ingressrulesfile
done
#bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/update-ingress.sh  $ingressdir $oldip '${EXTERNAL_IP}'