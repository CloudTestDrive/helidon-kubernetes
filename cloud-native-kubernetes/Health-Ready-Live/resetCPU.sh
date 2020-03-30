#!/bin/bash
echo Changing deployment CPU limits to 1 CPU
kubectl patch deployment storefront --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"1000m"}]'
kubectl patch deployment stockmanager --type='json' -n helidon -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/resources/limits/cpu", "value":"1000m"}]'
