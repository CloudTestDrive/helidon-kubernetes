#!/bin/bash -f
if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

echo "This script will setup the verrazano configuration in cluster $CLUSTER_CONTEXT_NAME"
echo "This script used the core kubernetes labs setup script so it will now perform those functions, you will need to respond to it's prompts"
bash ./core-kubernetes-lab-setup.sh $CLUSTER_CONTEXT_NAME
echo "Now the core lab setup has completed starting verrazzano core setup"
SAVED_PWD=`pwd`

cd MODULES_DIR
#bash ./verrazzano-setup.sh $CLUSTER_CONTEXT_NAME