#!/bin/bash -f

SCRIPT_NAME=`basename $0`
if [ $# = 0 ]
then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1sr arg either set or reset"
    echo "Optional"
    echo "  2nd arg the kubernetes context to use - defaults to one"
  echo "Cannot continue"
  exit 1
fi
CMD=$1
if [ $CMD = set ] || [ $CMD = reset ]
then
  echo "Will $CMD the storefront config"
else
  echo "You need to specify set or reset as the first arg"
  echo "Cannot continue"
  exit 2
fi

CLUSTER_CONTEXT_NAME=one
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

CONFDIR=$HOME/helidon-kubernetes/configurations
FRONTDIR=$CONFDIR/storefrontconf
STOREFRONT_CONF_DIR=$FRONTDIR/conf
STOREFRONT_BILLING_YAML=storefront-billing.yaml
STOREFRONT_DEST_YAML=$STOREFRONT_CONF_DIR/$STOREFRONT_BILLING_YAML
CUR_DIR=`pwd`

if [ "$CMD" = "set" ]
then
  # set action
  if [ -f "$STOREFRONT_BILLING_YAML" ]
  then
    cp $CUR_DIR/$STOREFRONT_BILLING_YAML $STOREFRONT_DEST_YAML
  else
    echo "Cannot locate $STOREFRONT_BILLING_YAML in the current directory ( $CUR_DIR ) cannot continue"
    exit 3
  fi
else
  # reset action
  if [ -f "$STOREFRONT_DEST_YAML" ]
  then
    echo "Removing $STOREFRONT_DEST_YAML"
    rm $STOREFRONT_DEST_YAML
  else
    echo "Cannot locate $STOREFRONT_DEST_YAML to remove, cannot continue"
    exit 4
  fi
fi
echo "Updating config maps"
# kubectl seems to heva problems replacing a config map, so let's just create it form the files and then apply it
# that will replace if needed
kubectl create configmap sf-config-map --from-file=$FRONTDIR/conf -o yaml --dry-run=client | kubectl apply --context $CLUSTER_CONTEXT_NAME -f -
echo "The config maps has been updated, restarting the storefront to pickup the change"
kubectl rollout restart deployment storefront