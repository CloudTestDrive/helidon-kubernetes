#!/bin/bash -f
ingressdir=$1
oldtext=$2
newtext=$3
currentcontext=`kubectl config current-context`
for ingresstemplatefile in $ingressdir/ingress*Rules.yaml 
do
   destfile=`echo $ingresstemplatefile | sed -e "s/Rules/Rules-$currentcontext"`
   echo Templating $ingresstemplatefile  to $destfile
   bash $HOME/helidon-kubernetes/setup/common/template-file.sh $ingresstemplatefile $destfile $oldtext.nip.io $newtext.nip.io
done