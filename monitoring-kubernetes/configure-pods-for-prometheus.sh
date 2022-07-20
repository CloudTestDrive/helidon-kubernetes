#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
DEPLOY_DIR=$HOME/helidon-kubernetes
cat $DEPLOY_DIR/stockmanager-deployment.yaml | sed -e 's/ #  prometheus.io/   prometheus.io/' | sed -e 's/ #annotations/ annotations/' > $DEPLOY_DIR/tmp
mv $DEPLOY_DIR/tmp $DEPLOY_DIR/stockmanager-deployment.yaml
kubectl apply -f $DEPLOY_DIR/stockmanager-deployment.yaml  --context $CLUSTER_CONTEXT_NAME
cat $DEPLOY_DIR/storefront-deployment.yaml | sed -e 's/ #  prometheus.io/   prometheus.io/' | sed -e 's/ #annotations/ annotations/' > $DEPLOY_DIR/tmp
mv $DEPLOY_DIR/tmp $DEPLOY_DIR/storefront-deployment.yaml
kubectl apply -f $DEPLOY_DIR/storefront-deployment.yaml --context $CLUSTER_CONTEXT_NAME