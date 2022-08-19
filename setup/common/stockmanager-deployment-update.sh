#!/bin/bash
if [ $# -lt 4 ]
  then
    echo "Missing arguments, you must provide these arguments in order :"
    echo "Operation to be performed this is one of set or reset"
    echo "Name of the OCIR host e.g. fra.ocir.io"
    echo "Name of the object storage namespace - this is a set of random letters and numbers usually"
    echo "Name of the OCIR repository for the namespace"
    exit -1 
fi

CMD=$1
OCIR_LOCATION=$2
OCIR_STORAGE_NAMESPACE=$3
OCIR_REPO=$4

HK_DIR=$HOME/helidon-kubernetes
SM_DIR=$HK_DIR/service-mesh/linkerd

if [ $CMD = set ] || [ $CMD = reset ]
then
  echo "Processing stockmanager deployment templates"
  for TEMPLATE_YAML in $HK_DIR/stockmanager-deployment-template.yaml $SM_DIR/stockmanager-deployment-broken-template.yaml $SM_DIR/stockmanager-deployment-v0.0.1-template.yaml $SM_DIR/stockmanager-deployment-v0.0.2-template.yaml
  do
    bash deployments-update.sh $CMD $TEMPLATE_YAML $OCIR_LOCATION $OCIR_STORAGE_NAMESPACE $OCIR_REPO
  done
else
  echo "Unknown operation $CMD, 1st argument must be either set or reset"
fi
