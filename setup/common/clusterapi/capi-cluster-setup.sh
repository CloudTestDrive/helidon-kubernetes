#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings
CAPI_SETTINGS_FILE=./capi-settings.sh

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ -d $CAPI_DIR ]
then
  echo "Will use $CAPI_DIR as the working directory"
else
  echo "Can't locate the directory $CAPI_DIR have you run the oci-capi-setup.sh script ?"
  exit 4
fi

if [ -z "$CAPI_PROVISIONER_REUSED" ]
then
  echo "no capi provisioner reuse information, has the oci-capi-setup.sh script been run ? cannot continue."
  exit 1
else
  echo "capi provisioner setup, continuing"
fi

if [ -z "$COMPARTMENT_OCID" ]
then
  echo "No COMPARTMENT_OCID set, have you run the compartment-setup.sh script ? Cannot continue"
  exit 2
fi

if [ -z "$USER_INITIALS" ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi


if [ -f $CAPI_SETTINGS_FILE ]
  then
    echo "Loading capi settings"
    source $CAPI_SETTINGS_FILE
  else 
    echo "No capi settings file ( $CAPI_SETTINGS_FILE ) cannot continue"
    exit 11
fi

if [ -x "$CLUSTERCTL_PATH" ]
then
  echo "Located clusterctl command"
else
  echo "clusterctl command should be $CLUSTERCTL_PATH but it's not found or not executable, have you run the downloaded-clusterctl.sh script ?"
  exit 2
fi

CAPI_CONTEXT_NAME=capi

if [ $# -gt 0 ]
then
  CAPI_CONTEXT_NAME=$1
  echo "Operating on capi context name $CAPI_CONTEXT_NAME"
else
  echo "Using default capi context name of $CAPI_CONTEXT_NAME"
fi

# we need an ssh key
SAVED_DIR=`pwd`
cd ../ssh-keys
bash ./ssh-key-setup.sh $HOME/ssh id_rsa_capi_$CAPI_CONTEXT_NAME
# the resulting keys will be  $HOME/ssh/id_rsa_capi_$CAPI_CONTEXT_NAME (.pub and .pem)
cd $SAVED_DIR


# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS"
  exit 99
else
  echo "Capi will create the cluster in compartment $COMPARTMENT_NAME"
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
CAPI_REUSED_NAME=CAPI_REUSED_$CAPI_CONTEXT_NAME
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
CAPI_REUSED="${!CAPI_REUSED_NAME}"
if [ -z $CAPI_REUSED ]
then
  echo "No reuse information for CAPI cluster $CAPI_CONTEXT_NAME"
else
  echo "This script has already configured a capi cluster for context $CAPI_CONTEXT_NAME, exiting"
  exit 0
fi

# is there already a context with that name ?
CONTEXT_NAME_EXISTS=`kubectl config get-contexts -o name | grep -w $CAPI_CONTEXT_NAME`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Using context name of $CAPI_CONTEXT_NAME"
else
  echo "A kubernetes context called $CAPI_CONTEXT_NAME already exists, this script cannot replace it."
  if [ $# -gt 0 ]
  then
    echo "Please re-run this script providing a different name than $CAPI_CONTEXT_NAME as the first argument"
  else
    echo "Please re-run this script but provide an argument for the context name as the first argument. The name you chose cannot be $CAPI_CONTEXT_NAME"
  fi
  exit 40
fi

# setup the core CAPI settings that we will always need, these can be overidden, but at least there will be a value for them

OCI_COMPARTMENT_ID=COMPARTMENT_OCID
NAMESPACE=capi-$CAPI_CONTEXT_NAME
NODE_MACHINE_COUNT=1
#ßOCI_IMAGE_ID
OCI_SSH_KEY=`cat "$HOME/ssh/id_rsa_capi_$CAPI_CONTEXT_NAME".pub`

CAPI_CONFIG_DIR=`pwd`/capi-config
echo "Checking for capi generic settings file"
GENERIC_CAPI_SETTINGS=$CAPI_CONFIG_DIR/general-capi-settings.sh
if [ -f $GENERIC_CAPI_SETTINGS ]
then
  echo "Located general capi settings file at $GENERIC_CAPI_SETTINGS"
else
  echo "Cannot locate general capi settings file at $GENERIC_CAPI_SETTINGS, cannot continue"
  exit 12
fi
echo "Loading generic capi settings"
source $GENERIC_CAPI_SETTINGS
 
echo "Checking for capi cluster specific settings file"
CLUSTER_SPECIFIC_CAPI_SETTINGS=$CAPI_CONFIG_DIR/cluster-specific-capi-settings-$CAPI_CONTEXT_NAME.sh
if [ -f $CLUSTER_SPECIFIC_CAPI_SETTINGS ]
then
  echo "Located capi cluster specific settings file at $CLUSTER_SPECIFIC_CAPI_SETTINGS"
  echo "Loading capi cluster specific settings"
  source $CLUSTER_SPECIFIC_CAPI_SETTINGS
else
  echo "Cannot locate capi cluster specific settings file $CLUSTER_SPECIFIC_CAPI_SETTINGS, no capi cluster specific overide settings will be applied"
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to generate and apply the yaml for the cluster API cluster named $CAPI_CONTEXT_NAME as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME defaulting to $REPLY"
else
  read -p "Do you want to generate and apply the yaml for the cluster API cluster named $CAPI_CONTEXT_NAME as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK stopping capi cluster creation"
  exit 1
fi

echo CAPI_YAML=$CAPI_DIR/capi-cluster-$CAPI_CONTEXT_NAME.yaml

echo "Generating cluster yaml into $CAPI_YAML"
$CLUSTERCTL_PATH/ generate cluster $CAPI_CONTEXT_NAME > $CAPI_YAML
#echo "$CAPI_REUSED_NAME=false" >> $SETTINGS