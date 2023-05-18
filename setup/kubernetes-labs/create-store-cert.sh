#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the external IP address for the Load Balancer"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
EXTERNAL_IP=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
echo "removing existing store certs"
touch tls-store-$EXTERNAL_IP.crt tls-store-$EXTERNAL_IP.key
rm tls-store-$EXTERNAL_IP.crt tls-store-$EXTERNAL_IP.key
echo "creating tls secret using step with common name of store.$EXTERNAL_IP.nip.io"
$HOME/keys/step certificate create store.$EXTERNAL_IP.nip.io tls-store-$EXTERNAL_IP.crt tls-store-$EXTERNAL_IP.key --profile leaf --not-after 8760h --no-password --insecure  --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key
echo "removing any existing tls-store secret from cluster $CLUSTER_CONTEXT_NAME"
kubectl delete secret tls-store --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "creating new tls-store secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret tls tls-store --key tls-store-$EXTERNAL_IP.key --cert tls-store-$EXTERNAL_IP.crt --context $CLUSTER_CONTEXT_NAME
echo "Created secret"