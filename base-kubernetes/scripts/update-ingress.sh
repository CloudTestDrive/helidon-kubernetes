#!/bin/bash -f
for ingressfile in $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules.yaml 
do
   echo Updating $ingressfile 
   bash $HOME/helidon-kubernetes/base-kubernetes/scripts/update-file.sh $ingressfile $1 $2
done