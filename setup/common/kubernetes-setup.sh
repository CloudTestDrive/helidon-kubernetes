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

if [ -z $USER_INITIALS ]
then
  echo Your initials have not been set, you need to run the initials-setup.sh script before you can run this script
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 2
fi

#Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OKE_REUSED_NAME=OKE_REUSED_$context_name
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo No reuse information for OKE context $context_name
else
  echo This script has already configured OKE details for context $context_name, exiting
  exit 3
fi

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS
  exit 99
else
  echo Operating in compartment $COMPARTMENT_NAME
fi


CLUSTER_NAME="$USER_INITIALS"lab
read -p "Do you want to use $CLUSTER_NAME as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME?" REPLY

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the name of the Kubernetes cluster to create / re-use, it must be a single word, e.g. TGDemo"
  read CLUSTER_NAME
  if [ -z "$CLUSTER_NAME" ]
  then
    echo "You do actually need to enter the new name for the Kubernetes cluster, exiting"
    exit 1
  fi
else     
  echo "OK, going to use $CLUSTER_NAME as the Kubernetes cluster name"
fi

# Do the variable redirection trick again
# Create a name using the variable
OKE_OCID_NAME=OKE_OCID_$context_name
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_OCID="${!OKE_OCID_NAME}"

if [ -z $OKE_OCID ]
then
  echo Checking for cluster $CLUSTER_NAME
  OKE_OCID=`oci ce cluster list --name $CLUSTER_NAME --compartment-id $COMPARTMENT_OCID | jq -j '.data[0].id'`
  if [ -z $OKE_OCID ]
  then
    echo Creating cluster $CLUSTER_NAME
    echo Downloading terraform
    git clone https://github.com/oracle-terraform-modules/terraform-oci-oke.git
    TF_DIR_BASE=`pwd`/terraform-oci-oke
    TF_DIR=$TF_DIR_BASE-$context
	mv $TF_DIR_BASE $TF_DIR
    TFP=$TF_DIR/provider.tf
    TFV=$TF_DIR/terraform.tfvars
    echo Configuring terraform
    cp oke-provider.tf $TFP
    cp oke-terraform.tfvars $TFV
    cd $TF_DIR
    echo Update provider.tf set OCI_REGION to $OCI_REGION
    bash ../update-file.sh $TFP OCI_REGION $OCI_REGION
    echo Update terraform.tfvars to set compartment OCID
    bash ../update-file.sh $TFV COMPARTMENT_OCID $COMPARTMENT_OCID
    echo Update terraform.tfvars to set tenancy OCID
    bash ../update-file.sh $TFV OCI_TENANCY $OCI_TENANCY
    echo Update terraform.tfvars to set OCI Region
    bash ../update-file.sh $TFV OCI_REGION $OCI_REGION
    echo Update terraform.tfvars to set Cluster name
    bash ../update-file.sh $TFV CLUSTER_NAME $CLUSTER_NAME
    echo Initialising Terraform
    terraform init
    echo Planning terraform deployment
    terraform plan --out=$TF_DIR/terraform.plan
    echo Applying terraform - this may take a while
    terraform apply $TF_DIR/terraform.plan
    echo Retrieving cluster OCID from Terraform
    OKE_OCID=`terraform output | grep cluster_id | awk '{print $3}' | sed -e 's/"//g'`
    echo OKE_OCID_$context_name=$OKE_OCID >> $SETTINGS
    echo OKE_REUSED_$context_name=false >> $SETTINGS
  else
    echo Located existing cluster named $CLUSTER_NAME in $COMPARTMENT_NAME
    echo OKE_OCID_$context_name=$OKE_OCID >> $SETTINGS
    echo OKE_REUSED_$context_name=true >> $SETTINGS
  fi
  echo Downloading the kube config file
  KUBECONF=$HOME/.kube/config
  oci ce cluster create-kubeconfig --cluster-id $OKE_OCID --file $KUBECONF --region $OCI_REGION --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT
  # chmod to be on the safe side sometimes things can have the wront permissions which caused helm to issue warnings
  chmod 600 $KUBECONF
  echo Renaming context to $context_name
  # the oci command sets the latest cluster as the default, let's rename it to one so it fits in with the rest of the lab instructions
  CURRENT_CONTEXT=`kubectl config current-context`
  kubectl config rename-context $CURRENT_CONTEXT $context_name

else
  CLUSTER_NAME=`oci ce cluster get --cluster-id $OKE_OCID | jq -j '.data.name'`
  if [ -z $CLUSTER_NAME ] 
  then
    echo Cannot locate a cluster with the specified OCID of $OKE_OCID
    echo Please check that the value of OKE_OCID_$context_name in $SETTINGS is correct if nor remove or replace it
    exit 5
  else
    echo Located cluster named $CLUSTER_NAME using OCID $OKE_OCID
    echo You are assumed to have downloaded the $HOME/kube/config file either by hand or using this script
    echo You are assumed to have updated the kubernetes configuration to set this cluster as the default either by hand or using this script
    echo You are assumed to have set the name for this clusters context in the config to be \"one\" either by hand or using this script
    # Flag this as reused and refuse to destroy it
    echo OKE_REUSED_$context_name=true >> $SETTINGS
  fi
fi