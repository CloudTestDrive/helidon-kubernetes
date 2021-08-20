#!/bin/bash
echo removing existing certs
touch tls-store.crt tls-store.key
rm tls-store.crt tls-store.key
echo creating tls secret using step with common name of store.$1.nip.io
$HOME/keys/step certificate create store.$1.nip.io tls-store.crt tls-store.key --profile leaf --not-after 8760h --no-password --insecure --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key
echo removing any existing tls-store secret
kubectl delete secret tls-store --ignore-not-found=true
echo creating new tls-store secret
kubectl create secret tls tls-store --key tls-store.key --cert tls-store.crt
echo Created secret