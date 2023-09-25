#!/bin/bash -f
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

echo "This script will destroy the verrazano configuration in cluster $CLUSTER_CONTEXT_NAME"
echo "This script used the core kubernrtes labs destroy script so it will now perform those functions, ou will need to respond to it's prompts"