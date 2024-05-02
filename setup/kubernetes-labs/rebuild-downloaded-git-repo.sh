#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
DEPARTMENT=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on supplied context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

DEPARTMENT=$1
REPO_CONFIGURED_FOR_SERVICES_NAME=`bash ../common/settings/to-valid-name.sh "REPO_CONFIGURED_FOR_SERVICES"_"$CLUSTER_CONTEXT_NAME"`

# reset the configuration flag - there won;t be anythign we can in the curren git repo as it will have been reset
bash ../common/delete-from-saved-settings.sh $REPO_CONFIGURED_FOR_SERVICES_NAME
bash ./configure-downloaded-git-repo.sh $DEPARTMENT $CLUSTER_CONTEXT_NAME