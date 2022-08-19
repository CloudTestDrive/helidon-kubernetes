#!/bin/bash -ff
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "the name of the cluster context"
  exit 1
fi
CLUSTER_CONTEXT_NAME=$1
bash ../settings/to-valid-name.sh  "SERVICE_MESH_METRICS_SERVER_"$CLUSTER_CONTEXT_NAME"_REUSED"