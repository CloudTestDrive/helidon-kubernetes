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


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OKE_REUSED_NAME=`bash ./get-oke-reused-name.sh $CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo "No reuse information for OKE context $CLUSTER_CONTEXT_NAME"
else
  echo "This script has already configured OKE details for context $CLUSTER_CONTEXT_NAME, exiting"
  exit 0
fi


#check for trying to re-use the context name
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name 2>/dev/null`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Using context name of $CLUSTER_CONTEXT_NAME"
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME already exists, this script cannot replace it."
  if [ $# -gt 0 ]
  then
    echo "Please re-run this script providing a different name than $CLUSTER_CONTEXT_NAME as the first argument"
  else
    echo "Please re-run this script but provide an argument for the context name as the first argument. The name you chose cannot be $CLUSTER_CONTEXT_NAME"
  fi
  exit 40
fi


# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID or $COMPARTMENT_OCID cant be located, please check you have set the correct value in $SETTINGS"
  exit 99
else
  echo "Operating in compartment $COMPARTMENT_NAME"
fi

CLUSTER_NAME="$USER_INITIALS"
CLUSTER_NAME_FULL="lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME"
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, using $CLUSTER_NAME_FULL question for cluster name defaulting to $REPLY"
else
  read -p "Do you want to use $CLUSTER_NAME_FULL as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the base name of the Kubernetes cluster to create / re-use, it must be a single word, e.g. tgemo. If a cluster with the name lab-$CLUSTER_CONTEXT_NAME-nameyouenter exists it will be re-used, if not a new cluster will be created named lab-$CLUSTER_CONTEXT_NAME-<your name>"
  read CLUSTER_NAME
  if [ -z "$CLUSTER_NAME" ]
  then
    echo "You do actually need to enter the new name for the Kubernetes cluster, exiting"
    exit 1
  fi
else     
  CLUSTER_NAME_FULL=lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME
  echo "OK, going to use $CLUSTER_NAME_FULL as the Kubernetes cluster name"
fi

# Do the variable redirection trick again
# Create a name using the variable
OKE_OCID_NAME=`bash ./get-oke-ocid-name.sh $CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OKE_OCID_NAME and save it
OKE_OCID="${!OKE_OCID_NAME}"

OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`

OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

# Where we will put the TF files, don't keep inthe git repo as they get clobbered when we rebuild it
TF_GIT_BASE=$HOME/oke-terraform

if [ -z $OKE_OCID ]
then
  echo "Checking for active cluster named $CLUSTER_NAME_FULL"
  OKE_OCID=`oci ce cluster list --name $CLUSTER_NAME_FULL --compartment-id $COMPARTMENT_OCID --lifecycle-state ACTIVE | jq -j '.data[0].id'`
  if [ -z $OKE_OCID ]
  then
    echo "Checking for cluster specific settings directory"
    TF_SOURCE_CONFIG_DIR=`pwd`/oke-terraform-config
    if [ -d $TF_SOURCE_CONFIG_DIR ]
    then
      echo "Located cluster specific settings as $TF_SOURCE_CONFIG_DIR"
    else
      echo "Cannot locate directory $TF_SOURCE_CONFIG_DIR, cannot continue"
      exit 10
    fi
    
    # set some defaults so we can ensure that there will be some data for these
    POOL_NAME=pool1
    WORKER_OCPUS=1
    WORKER_MEMORY=16
    WORKER_COUNT=3
    WORKER_BOOT_SIZE=50
    USE_SIGNED_IMAGES=false
    IMAGE_SIGNING_KEYS='[]'
    echo "Checking for teraform module generic settings file"
    GENERIC_OKE_TERRAFORM_SETTINGS=$TF_SOURCE_CONFIG_DIR/general-oke-terraform-settings.sh
    if [ -f $GENERIC_OKE_TERRAFORM_SETTINGS ]
    then
      echo "Located general OKE terraform specific settings file at $GENERIC_OKE_TERRAFORM_SETTINGS"
    else
      echo "Cannot locate general OKE terraform specific settings file at $GENERIC_OKE_TERRAFORM_SETTINGS, cannot continue"
      exit 12
    fi
    echo "Loading generic OKE terraform settings"
    source $GENERIC_OKE_TERRAFORM_SETTINGS
    
    echo "Checking for cluster specific settings file"
    CLUSTER_SPECIFIC_SETTINGS=$TF_SOURCE_CONFIG_DIR/cluster-specific-oke-terraform-settings-$CLUSTER_CONTEXT_NAME.sh
    if [ -f $CLUSTER_SPECIFIC_SETTINGS ]
    then
      echo "Located cluster specific settings file at $CLUSTER_SPECIFIC_SETTINGS"
      echo "Loading cluster specific settings"
      source $CLUSTER_SPECIFIC_SETTINGS
    else
      echo "Cannot locate cluster specific settings file $CLUSTER_SPECIFIC_SETTINGS, no cluster specific overide settings will be applied"
    fi
    
    # Check for the VCN Network address being set
    if [ -z $VCN_CLASS_B_NETWORK_CIDR_START ]
    then
      echo 'Unable to locate the VCN Network CIDR start variable ( VCN_CLASS_B_NETWORK_CIDR_START )'
      echo 'Cannot continue'
      exit 11
    else
      echo "Located VCN Network CIDR start as $VCN_CLASS_B_NETWORK_CIDR_START"
    fi
    # Check for the TF OKE module version
    if [ -z $TERRAFORM_OKE_MODULE_VERSION ]
    then
      echo 'Unable to locate the terraform-oke-module version ( TERRAFORM_OKE_MODULE_VERSION )'
      echo 'Cannot continue'
      exit 13
    else
      echo "Located terraform-oke-module version as $TERRAFORM_OKE_MODULE_VERSION"
    fi
    echo "Checking for VCN availability"
    bash ../resources/resource-minimum-check-region.sh vcn vcn-count 1
    AVAIL_VCN=$?

    if [ $AVAIL_VCN -eq 0 ]
    then
      echo 'You have enough Virtual CLoud Networks to create the OKE cluster'
    else
      echo "Sorry, but there are no available virtual cloud network resources available to create the Kubernetes cluster."
      echo "This script cannot continue"
      exit 50
    fi
    if [ -z "$WORKER_SHAPE" ]
    then
      let OCPU_COUNT="$WORKER_OCPUS*$WORKER_COUNT"
      echo "Checking for E4 or E3 $OCPU_COUNT processor availability for Kubernetes workers"
      # for now to get this done quickly just hard code the checks, at some point make this config driven
      bash ../resources/resource-minimum-check-ad.sh $OCI_TENANCY "compute" "standard-e4-core-count" $OCPU_COUNT
      AVAIL_E4_CORES=$?
      bash ../resources/resource-minimum-check-ad.sh $OCI_TENANCY "compute" "standard-e3-core-ad-count" $OCPU_COUNT
      AVAIL_E3_CORES=$?
      if [ $AVAIL_E4_CORES -eq 0 ]
      then
        WORKER_SHAPE=VM.Standard.E4.Flex
      elif [ $AVAIL_E3_CORES -eq 0 ]
      then
        WORKER_SHAPE=VM.Standard.E3.Flex
      else
        echo "Sorry, but there are no available cores available to create the Kubernetes cluster, this script cannot continue."
        echo "You will need to get some E3 or E4 cores to be able to create a Kubernetes cluster, if you are in a non free trial maybe switch to a different region"
        exit 50
      fi
    else
      echo "Using override worker shape of $WORKER_SHAPE, will not resource check"
    fi
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, Do you want to create cluster lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME using TF module verison $TERRAFORM_OKE_MODULE_VERSION and Kubernetes version $OKE_KUBERNETES_VERSION? e defaulting to $REPLY"
    else
      read -p "Do you want to create cluster lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME using TF module verison $TERRAFORM_OKE_MODULE_VERSION and Kubernetes version $OKE_KUBERNETES_VERSION? (y/n) " REPLY
    fi

    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, stopping"
      exit 0
    fi
    echo "Proceeding to create cluster lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME using TF module verison $TERRAFORM_OKE_MODULE_VERSION and Kubernetes version $OKE_KUBERNETES_VERSION"
    echo "Preparing terraform directory"
    SAVED_DIR=`pwd`
    UPDATE_FILE_SCRIPT=$HOME/helidon-kubernetes/setup/common/update-file.sh
    TF_GIT_BASE=$HOME/oke-terraform
    mkdir -p $TF_GIT_BASE
    cd $TF_GIT_BASE
    TF_DIR_BASE=$TF_GIT_BASE/terraform-oci-oke
    TF_DIR=$TF_DIR_BASE-$CLUSTER_CONTEXT_NAME
	mkdir -p $TF_DIR
	TF_PROVIDER_FILE=oke-provider.tf
	TF_MODULE_FILE=oke-module.tf
	TF_OUTPUTS_FILE=oke-outputs.tf
    TFP=$TF_DIR/$TF_PROVIDER_FILE
    TFM=$TF_DIR/$TF_MODULE_FILE
    TFO=$TF_DIR/$TF_OUTPUTS_FILE
    echo "Configuring terraform"
    cp $TF_SOURCE_CONFIG_DIR/$TF_PROVIDER_FILE $TFP
    cp $TF_SOURCE_CONFIG_DIR/$TF_MODULE_FILE $TFM
    cp $TF_SOURCE_CONFIG_DIR/$TF_OUTPUTS_FILE $TFO
    cd $TF_DIR
    echo "Update $TF_PROVIDER_FILE set OCI_REGION"
    bash $UPDATE_FILE_SCRIPT $TFP OCI_REGION $OCI_REGION
    echo "Update $TF_PROVIDER_FILE set OCI_HOME_REGION"
    bash $UPDATE_FILE_SCRIPT $TFP OCI_HOME_REGION $OCI_HOME_REGION
    echo "Update $TF_MODULE_FILE set POOL_NAME"
    bash $UPDATE_FILE_SCRIPT $TFM POOL_NAME $POOL_NAME
    echo "Update $TF_MODULE_FILE set WORKER_SHAPE"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_SHAPE $WORKER_SHAPE
    echo "Update $TF_MODULE_FILE set WORKER_OCPUS"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_OCPUS $WORKER_OCPUS
    echo "Update $TF_MODULE_FILE set WORKER_MEMORY"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_MEMORY $WORKER_MEMORY
    echo "Update $TF_MODULE_FILE set WORKER_COUNT"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_COUNT $WORKER_COUNT
    echo "Update $TF_MODULE_FILE set WORKER_SHAPE"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_BOOT_SIZE $WORKER_BOOT_SIZE
    echo "Update $TF_MODULE_FILE to set compartment OCID"
    bash $UPDATE_FILE_SCRIPT $TFM COMPARTMENT_OCID $COMPARTMENT_OCID
    echo "Update $TF_MODULE_FILE to set tenancy OCID"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_TENANCY $OCI_TENANCY
    echo "Update $TF_MODULE_FILE to set OCI Region"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_REGION $OCI_REGION
    echo "Update $TF_MODULE_FILE set OCI_HOME_REGION"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_HOME_REGION $OCI_HOME_REGION
    echo "Update $TF_MODULE_FILE to set Cluster name"
    bash $UPDATE_FILE_SCRIPT $TFM CLUSTER_NAME $CLUSTER_NAME
    echo "Update $TF_MODULE_FILE to set Label prefix to context"
    bash $UPDATE_FILE_SCRIPT $TFM K8S_CONTEXT $CLUSTER_CONTEXT_NAME
    echo "Update $TF_MODULE_FILE to set VCN CIDR"
    bash $UPDATE_FILE_SCRIPT $TFM VCN_CLASS_B_NETWORK_CIDR_START $VCN_CLASS_B_NETWORK_CIDR_START
    echo "Update $TF_MODULE_FILE to set OKE TF Module version"
    bash $UPDATE_FILE_SCRIPT $TFM TERRAFORM_OKE_MODULE_VERSION $TERRAFORM_OKE_MODULE_VERSION
    echo "Update $TF_MODULE_FILE to set OKE Kubernetes version"
    bash $UPDATE_FILE_SCRIPT $TFM OKE_KUBERNETES_VERSION $OKE_KUBERNETES_VERSION
    echo "Update $TF_MODULE_FILE to set OKE image signing required"
    bash $UPDATE_FILE_SCRIPT $TFM USE_SIGNED_IMAGES $USE_SIGNED_IMAGES
    echo "Update $TF_MODULE_FILE to set OKE image signing keys"
    bash $UPDATE_FILE_SCRIPT $TFM USE_SIGNED_IMAGES "$IMAGE_SIGNING_KEYS"
    
    echo "Downloading TF versions file"
    curl --silent https://raw.githubusercontent.com/oracle-terraform-modules/terraform-oci-oke/main/versions.tf --output $TF_DIR/versions.tf
    
    echo "Initialising Terraform"
    terraform init
    if [ $? -ne 0 ]
    then
      echo "Problem initialising terraform, cannot continue"
      exit 10
    fi
    echo "Planning terraform deployment"
    terraform plan --out=$TF_DIR/terraform.plan
    if [ $? -ne 0 ]
    then
      echo "Problem doing terraform plan, cannot continue"
      exit 11
    fi
    echo "Applying terraform - this may take a while"
    terraform apply $TF_DIR/terraform.plan
    if [ $? -ne 0 ]
    then
      echo "Problem applying terraform, cannot continue"
      exit 12
    fi
    echo "Retrieving cluster OCID from Terraform"
    OKE_OCID=`terraform output | grep cluster_id | awk '{print $3}' | sed -e 's/"//g'`
    if [ -z $OKE_OCID ]
    then
      echo 'ERROR unable to retrieve cluster OCID from the terraform output unable to continue'
      echo 'You need to manually download the config file, look at the OCI Web UI for this cluster'
      echo 'and click the "Access cluster" button to get the detailed instructions'
      echo 'Once you have downloaded the kubeconfig you will need to update your context.'
      echo 'Execute the following command to do this'
      echo "kubectl config rename-context `kubectl config current-context` $CLUSTER_CONTEXT_NAME"
      exit 1
    fi
    OKE_REUSED=false
    echo "Getting cluster netwoking info from terraform"
    OKE_VCN=`terraform output vcn_id |  sed -e 's/"//g'`
    OKE_LB_SUBNET_OCID=`terraform output subnet_ids | grep pub_lb | awk '{print $3}' | sed -e 's/"//g'`
    OKE_WORKER_SUBNET_OCID=`terraform output subnet_ids | grep workers | awk '{print $3}' | sed -e 's/"//g'`
    OKE_LB_NSG_OCID=`terraform output nsg_ids | grep pub_lb | awk '{print $3}' | sed -e 's/"//g'`
    OKE_WORKER_NSG_OCID=`terraform output nsg_ids | grep worker | awk '{print $3}' | sed -e 's/"//g'`
    cd $SAVED_DIR
  else
    echo "Located existing cluster named $CLUSTER_NAME_FULL in $COMPARTMENT_NAME checking its status"
    OKE_STATUS=`oci ce cluster list --name $CLUSTER_NAME_FULL --compartment-id $COMPARTMENT_OCID  --lifecycle-state ACTIVE | jq -j '.data[0]."lifecycle-state"'`
    if [ "$OKE_STATUS" = "ACTIVE" ]
    then
      echo "Cluster is Active, proceeding"
      # record what we're going to save, but to avoid a parallel ops race condition wait for the end before saving it
      OKE_REUSED=true
    else
      OKE_STATUS=`oci ce cluster list --name $CLUSTER_NAME_FULL --compartment-id $COMPARTMENT_OCID  | jq -j '.data[0]."lifecycle-state"'`
      echo "Cluster $CLUSTER_NAME_FULL in compartment $COMPARTMENT_NAME exists but is not active, it is in state $OKE_STATUS, it cannot be used."
      echo "Please re-run this script and use a different name cluster name"
      exit 20 
    fi
  fi
  # ensure the context file exists
  KUBECONF_DIR=$HOME/.kube
  OKE_KUBECONFIG=kubeconfig-oke-$CLUSTER_CONTEXT_NAME.config
  KUBECONF_FILE=$KUBECONF_DIR/config
  mkdir -p $KUBECONF_DIR
  if [ -f "$KUBECONF_FILE" ]
  then
    # create a backup
    cp $KUBECONF_FILE "$KUBECONF_FILE".bak 
  else
    # create a new one
    touch $KUBECONF_FILE
  fi
  echo "Getting the kube config file to local copy"
  oci ce cluster create-kubeconfig --cluster-id $OKE_OCID --file $OKE_KUBECONFIG --region $OCI_REGION --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT
  # chmod to be on the safe side sometimes things can have the wront permissions which caused helm to issue warnings
  chmod 600 $OKE_KUBECONFIG
  echo "Updating the kube config file - renaming context to $CLUSTER_CONTEXT_NAME"
  # the oci command sets the latest cluster as the default, let's rename it to one so it fits in with the rest of the lab instructions
  CURRENT_CONTEXT=`kubectl config current-context --kubeconfig=$OKE_KUBECONFIG`
  kubectl config rename-context $CURRENT_CONTEXT $CLUSTER_CONTEXT_NAME  --kubeconfig=$OKE_KUBECONFIG
  echo "Merging kube config files"
  MERGED_CONF=merged-$CLUSTER_CONTEXT_NAME.config
  KUBECONFIG=$KUBECONF_FILE:$OKE_KUBECONFIG kubectl config view --flatten >  $MERGED_CONF
  echo "Moving kube config file"
  rm $KUBECONF_FILE
  # Replace your old config with the new merged config
  mv $MERGED_CONF $KUBECONF_FILE 
  chmod 600 $KUBECONF_FILE
  # remove the local one
  rm $OKE_KUBECONFIG
  # it's now save to save the OCID's as we've finished
  echo "$OKE_OCID_NAME=$OKE_OCID" >> $SETTINGS
  echo "$OKE_REUSED_NAME=$OKE_REUSED" >> $SETTINGS
  KUBERNETES_CLUSTER_TYPE_NAME=`bash ../settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME`
  echo "$KUBERNETES_CLUSTER_TYPE_NAME=OKE" >> $SETTINGS
  KUBERNETES_VERSION_NAME=`bash ../settings/to-valid-name.sh "KUBERNETES_VERSION_"$CLUSTER_CONTEXT_NAME`
  echo "$KUBERNETES_VERSION_NAME=$OKE_KUBERNETES_VERSION" >> $SETTINGS
else
  CLUSTER_NAME=`oci ce cluster get --cluster-id $OKE_OCID | jq -j '.data.name'`
  if [ -z $CLUSTER_NAME ] 
  then
    echo "Cannot locate a cluster with the specified OCID of $OKE_OCID"
    echo "Please check that the value of OKE_OCID_$CLUSTER_CONTEXT_NAME in $SETTINGS is correct if nor remove or replace it"
    exit 5
  else
    echo "Located cluster named $CLUSTER_NAME using OCID $OKE_OCID"
    echo "You are assumed to have downloaded the $HOME/kube/config file either by hand or using this script"
    echo "You are assumed to have updated the kubernetes configuration to set this cluster as the default either by hand or using this script"
    echo "You are assumed to have set the name for this clusters context in the config to be \"one\" either by hand or using this script"
    # Flag this as reused and refuse to destroy it
    echo "$OKE_REUSED_NAME=true" >> $SETTINGS
  fi
fi

echo "Switching kubernetes context to the specified one"
kubectl config use-context $CLUSTER_CONTEXT_NAME
# record some core networking info
CLUSTER_NETWORK_FILE=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME
echo "Saving network information for cluster $CLUSTER_CONTEXT_NAME to $CLUSTER_NETWORK_FILE"
echo "#Network information for cluster $CAPI_CONTEXT_NAME" > $CLUSTER_NETWORK_FILE
echo "export VCN_OCID=$OKE_VCN" >> $CLUSTER_NETWORK_FILE
echo "export LB_SUBNET_OCID=$OKE_LB_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "export WORKER_SUBNET_OCID=$OKE_WORKER_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "export LB_NSG_OCID=$OKE_LB_NSG_OCID" >> $CLUSTER_NETWORK_FILE
echo "export WORKER_NSG_OCID=$OKE_WORKER_NSG_OCID" >> $CLUSTER_NETWORK_FILE