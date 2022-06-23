#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo "Missing arguments, you must provide the name of the kubernetes context to switch to"
    exit -1
    
fi
newcontext=$1
if [ $# -eq 1 ]
  then
    echo "Switching the kubernetes context to $newcontext - this will apply across all calls unless you overrite using --context=<name> or switch to a new default context"
    read -p "Proceed (y/n) ?" 
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping confirmation, switching the kubernetes context to $newcontext - this will apply across all calls unless you overrite using --context=<name> or switch to a new default context"
fi

kubectl config use-context $newcontext

echo Switched, new default context is is
kubectl config current-context