#!/bin/bash
SCRIPT_NAME=`basename $0`
MESH_SETTINGS=./oci-service-mesh-settings.sh

if [ -f "$MESH_SETTINGS" ]
then
  echo "$SCRIPT_NAME loading mesh specific settings"
  source $MESH_SETTINGS
else
  echo "$SCRIPT_NAME unable to locate mesh specific settings, cannot continue"
  exit 30
fi
CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

echo "Destroying all cluster specific templates"
echo $OCI_MESH_DIR/*-"$CLUSTER_CONTEXT_NAME".yaml
rm $OCI_MESH_DIR/*-"$CLUSTER_CONTEXT_NAME".yaml