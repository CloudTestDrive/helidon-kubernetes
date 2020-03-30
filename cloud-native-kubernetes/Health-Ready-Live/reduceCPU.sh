#!/bin/bash
echo Changing deployment CPU limits to 0.2 CPU
kubectl patch deployment storefront --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"200m"}]'
kubectl patch deployment stockmanager --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"200m"}]'
