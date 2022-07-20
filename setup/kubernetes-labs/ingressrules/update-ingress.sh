#!/bin/bash -f
ingressdir=$1
oldtext=$2
newtext=$3
for ingressfile in $ingressdir/ingress*Rules.yaml 
do
   echo "Updating $ingressfile"
   bash $HOME/helidon-kubernetes/setup/common/update-file.sh $ingressfile $oldtext.nip.io $newtext.nip.io
done