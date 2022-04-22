#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

# extract the specific settings for the cluster we're dealing with
#Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OKE_REUSED_NAME=OKE_REUSED_$CLUSTER_CONTEXT_NAME
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo "No reuse information for OKE cannot safely continue, you will have to destroy it manually"
  exit 1
fi


# Where we will put the TF files, don't keep inthe git repo as they get clobbered when we rebuild it
TF_GIT_BASE=$HOME/oke-labs-terraform

if [ -d $TF_GIT_BASE ]
then
  echo "Located saved terraform state directory"
else
  echo "Unable to locate $TF_GIT_BASE which is where the saved terraform information is held, cannot proceed"
  exit 2
fi

TF_DIR=$TF_GIT_BASE/terraform-oci-oke-$CLUSTER_CONTEXT_NAME

if [ $OKE_REUSED = true ]
then
  echo "You have been using a cluster that was not created by these scripts, as it may"
  echo "contain other resources this script cannot delete it, you will need to destroy the"
  echo "cluster by hand and then remove the variables OKE_REUSE_$CLUSTER_CONTEXT_NAME"
  echo "and OKE_OCID_$CLUSTER_CONTEXT_NAME from $SETTINGS and delete $TF_DIR"
  exit 0
fi


# Do the variable redirection trick again
# Create a name using the variable
OKE_OCID_NAME=OKE_OCID_$CLUSTER_CONTEXT_NAME
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_OCID="${!OKE_OCID_NAME}"

if [ -z $OKE_OCID ]
then 
  echo "No OKE OCID information found for context $CLUSTER_CONTEXT_NAME , cannot continue"
  exit 3
fi

SAVED_DIR=`pwd`
if [ -d $TF_DIR ]
then
  cd $TF_DIR
  TFS=$TF_DIR/terraform.tfstate
  if [ -e $TFS ]
  then
    echo "Planning destrucion"
    terraform plan -destroy -out=$TF_DIR/destroy.plan
    echo "Destroying cluster"
    terraform apply -destroy $TF_DIR/destroy.plan
    echo "Removing terraform scripts"
    rm -rf $TF_DIR
    cd $SAVED_DIR
    bash ./delete-from-saved-settings.sh OKE_OCID_$CLUSTER_CONTEXT_NAME
    bash ./delete-from-saved-settings.sh OKE_REUSED_$CLUSTER_CONTEXT_NAME
    echo "Removing context $CLUSTER_CONTEXT_NAME from the local kubernetes configuration"
    CLUSTER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME | grep -v NAMESPACE | sed -e 's/*//' | awk '{print $2}'`
    USER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME | grep -v NAMESPACE | sed -e 's/*//' | awk '{print $3}'`
    kubectl config delete-user $USER_INFO
    kubectl config delete-cluster $CLUSTER_INFO
    kubectl config delete-context $CLUSTER_CONTEXT_NAME
    echo "The current kubernetes context has been removed, if you have others in your configuration you will need to select it using kubectl configuration set-context context-name"
  else
    echo "no state file, nothing to destroy"
    echo "cannot proceed"
    exist 4
  fi
else
  echo "$TF_DIR not found, nothing we can plan a destruction around"
fi