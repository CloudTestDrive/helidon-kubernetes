#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "SCRIPT_NAME Loading existing settings"
    source $SETTINGS
  else 
    echo "SCRIPT_NAME No existing settings, cannot continue"
    exit 10
fi

if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi
KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME=`bash ../common/settings/to-valid-name.sh KUBERNETES_SERVICES_CONFIGURED_$CLUSTER_CONTEXT_NAME`

if [ -z "${!KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME}" ]
then
  echo "No record of installing in cluster $CLUSTER_CONTEXT_NAME, cannot continue"
  exit 0
else
  echo "This script has  previously configured your Kubernetes cluster $CLUSTER_CONTEXT_NAME it will attempt to remove those services."
fi

#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Kubernetes context name of $CLUSTER_CONTEXT_NAME does not exist, cannot continue."
  exit 0
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME exists, continuing"
fi

if [ -z "$AUTO_CONFIRM" ]
then
   read -p "Do you want to auto confirm this script tearing down $CLUSTER_NETWORK (y/n) " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then  
    echo "OK, will prompt you"
    export AUTO_CONFIRM=false
  else     
  echo "OK, will take the default answer where possible"
    export AUTO_CONFIRM=true
  fi
fi

# run the pre-existing script
bash ./resetEntireCluster.sh $CLUSTER_CONTEXT_NAME
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the cluster services, cannot continue"
  exit $RESP
fi

bash ../common/delete-from-saved-settings.sh $KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME
