#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "Missing arguments supplied, you must provide the directory to process"
    exit -1 
fi

ingressdir=$1

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
currentcontext=`kubectl config current-context`
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confiorm set - Removing the ingress rules yaml for context $currentcontext in $ingressdir defaulting to $REPLY"
else
  echo "Removing the ingress rules yaml for context $currentcontext in $ingressdir"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
   echo "OK, exiting"
   exit 1
else
    echo "OK, about to remove the customised ingress rules"
fi

echo "Removing the ingress rules yaml for context $currentcontext in $ingressdir"
for ingressrulesfile in $ingressdir/ingress*Rules-$currentcontext.yaml 
do
  echo "Removing ingress rules yaml $ingressrulesfile"
  rm $ingressrulesfile
done
