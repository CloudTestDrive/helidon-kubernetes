#!/bin/bash
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
CONFDIR=$HOME/helidon-kubernetes/configurations
MGRDIR=$CONFDIR/stockmanagerconf
FRONTDIR=$CONFDIR/storefrontconf
echo "Deleting existing store front secrets"
echo "sf-conf"
kubectl delete secret sf-conf-secure --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Deleting existing stock manager secrets"
echo "sm-conf"
kubectl delete secret sm-conf-secure --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "sm-wallet-atp"
kubectl delete secret sm-wallet-atp --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "stockmanagerdb"
kubectl delete secret stockmanagerdb --ignore-not-found=true --context $CLUSTER_CONTEXT_NAME
echo "Deleted secrets"
echo "Secrets remaining in namespace are "
kubectl get secret --context $CLUSTER_CONTEXT_NAME
echo "Creating stock manager secrets"
echo "stockmanagerdb"
kubectl apply -f $MGRDIR/databaseConnectionSecret.yaml --context $CLUSTER_CONTEXT_NAME
echo "sm-wallet-atp"
kubectl create secret generic sm-wallet-atp --from-file=$MGRDIR/Wallet_ATP --context $CLUSTER_CONTEXT_NAME
echo "Creating stockmanager secrets"
kubectl create secret generic sm-conf-secure --from-file=$MGRDIR/confsecure --context $CLUSTER_CONTEXT_NAME
echo "Creating store front secrets"
kubectl create secret generic sf-conf-secure --from-file=$FRONTDIR/confsecure --context $CLUSTER_CONTEXT_NAME
echo "Existing in namespace are "
kubectl get secrets --context $CLUSTER_CONTEXT_NAME

