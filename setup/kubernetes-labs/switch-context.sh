#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo "Missing arguments, you must provide the name of the kubernetes context to switch to"
    exit -1
    
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
newcontext=$1
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Switching the kubernetes context to $newcontext - this will apply across all calls unless you overrite using --context=<name> or switch to a new default context defaults t' $REPLY"
else
  echo "Switching the kubernetes context to $newcontext - this will apply across all calls unless you overrite using --context=<name> or switch to a new default context"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
    echo "Switching the kubernetes context to $newcontext - this will apply across all calls unless you overrite using --context=<name> or switch to a new default context"
fi

kubectl config use-context $newcontext

echo "Switched, new default context is is"
kubectl config current-context