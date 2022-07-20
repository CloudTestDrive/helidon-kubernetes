#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

CLUSTER_CONTEXT_NAME=one

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
  echo "This script has already un-configured your Kubernetes cluster $CLUSTER_CONTEXT_NAME it will attempt to remove those services."
fi

#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Kubernetes context name of $CLUSTER_CONTEXT_NAME does not exist, cannot continue."
  echo "have you run the kubernetes-setup.sh script ?"
  exit 0
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME exists, continuing"
fi

if [ -z "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" ]
then
  echo "WARNING, cannot identify the number of clusters with installed services. This script will"
  echo "reset the database configurations. If you have more than one cluster this may cause problems"
  export KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES=1
fi


let KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES="$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES-1"
bash ../common/delete-from-saved-settings.sh KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES
if [ "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" = 0 ]
then
  echo "This is the last cluster, the scripts will reset the database configuration"
else
  echo "There are remaining clusters with services installed, the scripts will not touch the common db configuration"
  echo "KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES=$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" >> $SETTINGS
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