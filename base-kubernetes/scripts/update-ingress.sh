#!/bin/bash -f
foreach ingressfile ( $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules.yaml )
   echo Updating $ingressfile replacing $1 with $2
   $HOME/helidon-kubernetes/base-kubernetes/scripts/update-file.sh $ingressfile $1 $2
end