#!/bin/bash -f
currentcontext=`kubectl config current-context`
for ingressfile in $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules-$currentcontext.yaml 
do
   echo Applying $ingressfile
   kubectl apply -f $ingressfile
done