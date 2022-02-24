#!/bin/bash -f
DEPLOY_DIR=$HOME/helidon-kubernertes
cat $DEPLOY_DIR/stockmanager-deployment.yaml | sed -e 's/ #  p/   p/' | sed -e 's/ #a/ a/' > $DEPLOY_DIR/tmp
mv $DEPLOY_DIR/tmp $DEPLOY_DIR/stockmanager-deployment.yaml
kubectl apply -f $DEPLOY_DIR/stockmanager-deployment.yaml
cat $DEPLOY_DIR/storefront-deployment.yaml | sed -e 's/ #  p/   p/' | sed -e 's/ #a/ a/' > $DEPLOY_DIR/tmp
mv $DEPLOY_DIR/tmp $DEPLOY_DIR/storefront-deployment.yaml
kubectl apply -f $DEPLOY_DIR/storefront-deployment.yaml