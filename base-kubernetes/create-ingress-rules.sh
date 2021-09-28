#!/bin/bash -f
for ingressfile in $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules.yaml 
do
   echo Applying $ingressfile
   kubectl apply -f  $ingressfile
done