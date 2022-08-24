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
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

for TEMPLATE in $OCI_MESH_DIR/*template.yaml
do
  TEMPLATE_DIR=`dirname $TEMPLATE`
  TEMPLATE_BASE=`basename $TEMPLATE -template.yaml`
  OUTPUT_YAML="$TEMPLATE_DIR/$TEMPLATE_BASE""-""$CLUSTER_CONTEXT_NAME".yaml
  bash ../../common/template-file.sh $TEMPLATE $OUTPUT_YAML COMPARTMENT_OCID $COMPARTMENT_OCID
done