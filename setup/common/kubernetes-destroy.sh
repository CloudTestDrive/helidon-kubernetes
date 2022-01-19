#!/bin/bash -f

context_name=one

if [ $# -gt 0 ]
then
  context_name=$1
  echo Operating on context name $context_name
else
  echo Using default context name of $context_name
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

# extract the specific settings for the cluster we're dealing with
#Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OKE_REUSED_NAME=OKE_REUSED_$context_name
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo No reuse information for OKE cannot safely continue, you will have to destroy it manually
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

TF_DIR=$TF_GIT_BASE/terraform-oci-oke-$context_name

if [ $OKE_REUSED = true ]
then
  echo You have been using a cluster that was not created by these scripts, as it may contain other resources this script cannot delete it, you will need to destroy the cluster by hand
  echo and then remove the variables OKE_REUSE_$context_name and OKE_OCID_$context_name from $SETTINGS and delete $TF_DIR
  exit 2
fi


# Do the variable redirection trick again
# Create a name using the variable
OKE_OCID_NAME=OKE_OCID_$context_name
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_OCID="${!OKE_OCID_NAME}"

if [ -z $OKE_OCID ]
then 
  echo No OKE OCID information found for context $context_name , cannot continue
  exit 3
fi

SAVED_DIR=`pwd`
if [ -d $TF_DIR ]
then
  cd $TF_DIR
  TFS=$TF_DIR/terraform.tfstate
  if [ -e $TFS ]
  then
    echo Planning destrucion
    terraform plan -destroy -out=$TF_DIR/destroy.plan
    echo Destroying cluster
    terraform apply -destroy $TF_DIR/destroy.plan
    echo Removing terraform scripts
    rm -rf $TF_DIR
    cd $SAVED_DIR
    bash ./delete-from-saved-settings.sh OKE_OCID_$context_name
    bash ./delete-from-saved-settings.sh OKE_REUSED_$context_name
    echo Removing context $context_name from the local kubernetes configuration
    kubectl config delete-context $context_name
    echo The current kubernetes context has been removed, if you have others in your configuration you will need to select it using kubectl configuration set-context context-name
  else
    echo no state file, nothing to destroy
    echo cannot proceed
    exist 4
  fi
else
  echo $TF_DIR not found, nothing we can plan a destruction around
fi