#!/bin/bash -f
foreach ingressfile ( $HOME/helidon-kubernetes/base-kubernetes/ingress*Rules.yaml )
   echo Applying $ingressfile
   $kubectl apply -f  $ingressfile
end