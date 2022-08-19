#!/bin/bash
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
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

OCI_MESH_DIR=$HOME/helidon-kubernetes/service-mesh/oci-service-mesh

bash ../../common/update-file.sh $OCI_MESH_DIR/mesh-"$CLUSTER_CONTEXT_NAME".yaml CERT_AUTHORITY_OCID $CERT_AUTHORITY_OCID
