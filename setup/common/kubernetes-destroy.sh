#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

if [ -z $OKE_REUSED ]
then
  echo No reuse information for OKE cannot safely continue, you will have to destroy it manually
  exit 1
fi


TF_DIR=`pwd`/terraform-oci-oke

if [ $OKE_REUSED = true ]
then
  echo You have been using a cluster that was not created by these scripts, as it may contain other resources this script cannot delete it, you will need to destroy the cluster by hand
  then remove OKE_REUSE and OKE_OCID from $SETTINGS and delete $TF_DIR
  exit 2
fi

if [ -z $OKE_OCID ]
then 
  echo No OKE OCID information found, cannot continue
  exit 3
fi

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
    cd ..
    echo Removing terraform scripts
    rm -rf $TF_DIR
    bash ./delete-from-saved-settings.sh OKE_OCID
    bash ./delete-from-saved-settings.sh OKE_REUSED 
  else
    echo no state file, nothing to destroy
    echo cannot proceed
    exist 4
  fi
else
  echo $TF_DIR not found, nothign we can plan a destruction around
fi