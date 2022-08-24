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


if [ -z "$CERT_AUTHORITY_OCID" ]
  then
    echo "$SCRIPT_NAME No certificate authority is setup, have you run the cert-authority-setup.sh scripts ?"
    exit 20
fi

bash ./mesh-template-setup.sh $CLUSTER_CONTEXT_NAME
bash ./cert-authority-setup.sh $CLUSTER_CONTEXT_NAME
