#!/bin/bash
echo "removing existing store certs"
touch tls-store-$1.crt tls-store-$1.key
rm tls-store-$1.crt tls-store-$1.key
echo "creating tls secret using step with common name of store.$1.nip.io"
$HOME/keys/step certificate create store.$1.nip.io tls-store-$1.crt tls-store-$1.key --profile leaf --not-after 8760h --no-password --insecure  --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key
echo "removing any existing tls-store secret"
kubectl delete secret tls-store --ignore-not-found=true
echo "creating new tls-store secret"
kubectl create secret tls tls-store --key tls-store-$1.key --cert tls-store-$1.crt
echo "Created secret"