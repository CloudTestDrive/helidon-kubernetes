#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings, cannot continue"
    exit 10
fi


if [ -z "$USER_INITIALS" ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

if [ -z "$IMAGES_READY" ]
then
  echo "The container images have not been built, have you run the image-environment-setup.sh script ?"
  exit 20
else 
  echo "The images have been built and uploaded to the repo"
fi

if [ -z "$REPO_CONFIGURED_FOR_SERVICES" ]
then
  echo "The repo has not been configured for the database and other configuration information, cannot proceed as the YAML is not configured"
  exit 30
fi

if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
   read -p "Do you want to auto confirm this script setting up $CLUSTER_NETWORK (y/n) " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then  
    echo "OK, will prompt you"
    export AUTO_CONFIRM=false
  else     
  echo "OK, will take the default answer where possible"
    export AUTO_CONFIRM=true
  fi
fi
CONTEXT_MATCH=`kubectl config get-contexts --output=name | grep -w $CLUSTER_CONTEXT_NAME`

if [ -z $CONTEXT_MATCH ]
then
  echo "context $CLUSTER_CONTEXT_NAME not found, unable to continue"
  exit 2
else
  echo "Context $CLUSTER_CONTEXT_NAME found"
fi
CLUSTER_NETWORK=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME

if [ -f $CLUSTER_NETWORK ]
then
  echo "Located cluster networking config info file $CLUSTER_NETWORK"
else
  echo "Cannot locate cluster networking config info file $CLUSTER_NETWORK, this may be problematic if installing into a non OKE cluster"
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, continue even with missing $CLUSTER_NETWORK defaulting to $REPLY"
  else
    read -p "Do you want to continue even with missing $CLUSTER_NETWORK (y/n) " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, will stop the kubernetes services setup"
    exit 30
  else     
    echo "Continuing, if this is a non OKE cluster then you may have problems"
  fi
fi

KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME=`bash ../common/settings/to-valid-name.sh KUBERNETES_SERVICES_CONFIGURED_$CLUSTER_CONTEXT_NAME`

if [ -z "${!KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME}" ]
then
  echo "No record of installing in cluster $CLUSTER_CONTEXT_NAME, continuing"
else
  echo "This script has already configured your Kubernetes cluster $CLUSTER_CONTEXT_NAME, to reset it run the kubernetes-services-destroy.sh script, stopping."
  exit 0
fi

#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Kubernetes context name of $CLUSTER_CONTEXT_NAME does not exist, cannot continue."
  exit 40
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME exists, continuing"
fi

# run the pre-existing script
bash ./configureHelmAndFullyInstallCluster.sh $USER_INITIALS $CLUSTER_CONTEXT_NAME

RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure setting up the cluster services, cannot continue"
  exit $RESP
fi

echo "$KUBERNETES_SERVICES_CONFIGURED_SETTING_NAME=true" >> $SETTINGS
