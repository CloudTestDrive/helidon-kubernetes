#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


COMPARTMENT_NAME=CTDOKE

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
  AUTO_CONFIRM=n
fi

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME=`bash ../common/settings/to-valid-name.sh KUBERNETES_SERVICES_CONFIGURED_$CLUSTER_CONTEXT_NAME`

if [ -z "${!KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME}" ]
then
  echo "No record of installing in cluster $CLUSTER_CONTEXT_NAME, continuing"
else
  echo "This script has already configured your Kubernetes cluster $CLUSTER_CONTEXT_NAME, to reset it run the kubernetes-services-destroy.sh script, stopping."
  exit 0
fi

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Kubernetes context name of $CLUSTER_CONTEXT_NAME does not exist, cannot continue."
  echo "have you run the kubernetes-setup.sh script ?"
  exit 40
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME exists, continuing"
fi

# run the pre-existing script
bash ./configureGitAndFullyInstallCluster.sh $USER_INITIALS $CLUSTER_CONTEXT_NAME skip

RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure setting up the cluster services, cannot continue"
  exit $RESP
fi

echo "$KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME=true" >> $SETTINGS