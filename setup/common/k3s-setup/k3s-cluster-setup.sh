#!/bin/bash -f

SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
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
#if [ -z $VAULT_OCID ]
#then
#  echo "Your VAULT_OCID has not been set, you need to run the vault-setup.sh before you can run this script"
#  exit 2
#fi
SAVED_DIR=`pwd`
#cd ../vault
#VAULT_KEY_NAME_BASE=AES
#VAULT_KEY_NAME=`bash ./vault-key-get-key-name.sh $VAULT_KEY_NAME_BASE`
#VAULT_KEY_OCID_NAME=`bash ./vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`
#VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"
#cd $SAVED_DIR
#if [ -z $VAULT_KEY_OCID ]
#then
#  echo "Your VAULT_KEY_OCID has not been set for key $VAULT_KEY_NAME_BASE, you need to run the vault-key-setup.sh to create an AES key named $VAULT_KEY_NAME before you can run this script"
#  exit 2
#fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
K3S_REUSED_NAME=`bash ../settings/to-valid-name.sh  "K3S_REUSED_"$CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in K3S_REUSED_NAME and save it
K3S_REUSED="${!K3S_REUSED_NAME}"
if [ -z $K3S_REUSED ]
then
  echo "No reuse information for K3S context $CLUSTER_CONTEXT_NAME"
else
  echo "This script has already configured K3S details for context $CLUSTER_CONTEXT_NAME, exiting"
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

# make sure we can get some availability domain info
UPPER_CASE_REGION=`echo $OCI_REGION | tr [a-z] [A-Z]`
AVAILABILITY_DOMAIN=`oci iam availability-domain list --compartment-id $OCI_TENANCY | jq -r '.data[] | .name' | grep $UPPER_CASE_REGION | tail -n 1`

if [ -z "$AVAILABILITY_DOMAIN" ]
then
  echo "Unable to locate any availability domains, cannot continue"
  exit 100
fi

CLUSTER_NAME="$USER_INITIALS"
CLUSTER_NAME_FULL="lab-$USER_INITIALS-$CLUSTER_CONTEXT_NAME"
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to use $CLUSTER_NAME_FULL as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME  defaulting to $REPLY"
else
  read -p "Do you want to use $CLUSTER_NAME_FULL as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, please enter the base name of the Kubernetes cluster to create / re-use, it must be a single word, e.g. tgemo. If a cluster with the name lab-<your initials>-nameyouenter exists it will be re-used, if not a new cluster will be created named lab-$CLUSTER_CONTEXT_NAME-<your name>"
  read CLUSTER_NAME
  if [ -z "$CLUSTER_NAME" ]
  then
    echo "You do actually need to enter the new name for the Kubernetes cluster, exiting"
    exit 1
  fi
  CLUSTER_NAME_FULL="lab-$USER_INITIALS-$CLUSTER_NAME"
else     
  echo "OK, going to use $CLUSTER_NAME_FULL as the Kubernetes cluster name"
fi

# we need to ssh between the control plane and workers so ...
PRE_SSH_SAVED_DIR=`pwd`
cd ../ssh-keys
bash ./ssh-key-setup.sh $HOME/ssh id_rsa_k3s_$CLUSTER_CONTEXT_NAME
# the resulting keys will be  $HOME/ssh/id_rsa_k3s_$CLUSTER_CONTEXT_NAME (.pub and .pem)
K3S_SSH_PRIVATE_KEY_PATH="$HOME/ssh/id_rsa_k3s_""$CLUSTER_CONTEXT_NAME"
K3S_SSH_PUBLIC_KEY_PATH="$HOME/ssh/id_rsa_k3s_""$CLUSTER_CONTEXT_NAME"".pub"
cd $PRE_SSH_SAVED_DIR

OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`

OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

# Where we will put the TF files, don't keep inthe git repo as they get clobbered when we rebuild it
TF_GIT_BASE=$HOME/k3s-terraform

    echo "Checking for cluster specific settings directory"
    TF_SOURCE_CONFIG_DIR=`pwd`/k3s-terraform-config
    if [ -d $TF_SOURCE_CONFIG_DIR ]
    then
      echo "Located cluster specific settings as $TF_SOURCE_CONFIG_DIR"
    else
      echo "Cannot locate directory $TF_SOURCE_CONFIG_DIR, cannot continue"
      exit 10
    fi
    
    # set some defaults so we can ensure that there will be some data for these
    K3S_ENVIRONMENT="lab"
    K3S_KUBERNETES_VERSION="latest"
    # set these to ensure that there will be some defaults
    COMPUTE_SHAPE="VM.Standard.E4.Flex"
    CONTROL_PLANE_OCPUS=1
    CONTROL_PLANE_MEMORY=16
    CONTROL_PLANE_EXTRA_NODE_COUNT=0
    CONTROL_PLANE_BOOT_SIZE=50
    WORKER_OCPUS=1
    WORKER_MEMORY=16
    WORKER_COUNT=3
    WORKER_BOOT_SIZE=50
    K3S_CLUSTER_DYNAMIC_GROUP_NAME="$USER_INITIALS"k3sComputeDynamicGroup"$CLUSTER_CONTEXT_NAME"
    K3S_CLUSTER_POLICY_NAME="$USER_INITIALS"k3sComputePolicy"$CLUSTER_CONTEXT_NAME"
    
    INSTALL_NGINX_INGRESS=false
    INSTALL_CERT_MGR=false
    CERT_MGR_VERSION="v1.8.2"
    CERT_MGR_EMAIL="changeme@example.com"
    INSTALL_LONGHORN=false
    LONGHORN_VERSION=false
    LONGHORN_VERSION="v1.2.3"
    INSTALL_OCI_CCM=true
    OCI_CCM_VERSION="v1.24.0"
    
    PUBLIC_KUBEAPI=true
    PROVIDER_VERSION=">= 4.64.0"
    
    #CLUSTER_TZ=`basename \`readlink -f /etc/localtime\``
    #DATASTORE_TYPE="etcd"
    
    # we've setup the defaults, next stage is to see if there is any override on them
    
    echo "Checking for teraform module generic settings file"
    GENERIC_K3S_TERRAFORM_SETTINGS=$TF_SOURCE_CONFIG_DIR/general-k3s-terraform-settings.sh
    if [ -f $GENERIC_K3S_TERRAFORM_SETTINGS ]
    then
      echo "Located general K3S terraform specific settings file at $GENERIC_K3S_TERRAFORM_SETTINGS"
    else
      echo "Cannot locate general K3S terraform specific settings file at $GENERIC_K3S_TERRAFORM_SETTINGS, cannot continue"
      exit 12
    fi
    echo "Loading generic K3S terraform settings"
    source $GENERIC_K3S_TERRAFORM_SETTINGS
    
    echo "Checking for cluster specific settings file"
    CLUSTER_SPECIFIC_SETTINGS=$TF_SOURCE_CONFIG_DIR/cluster-specific-k3s-terraform-settings-$CLUSTER_CONTEXT_NAME.sh
    if [ -f $CLUSTER_SPECIFIC_SETTINGS ]
    then
      echo "Located cluster specific settings file at $CLUSTER_SPECIFIC_SETTINGS"
      echo "Loading cluster specific settings"
      source $CLUSTER_SPECIFIC_SETTINGS
    else
      echo "Cannot locate cluster specific settings file $CLUSTER_SPECIFIC_SETTINGS, no cluster specific overide settings will be applied"
    fi
    
    # Check for the VCN Network address being set
    if [ -z $VCN_CIDR ]
    then
      echo 'Unable to locate the VCN Network CIDR start variable ( VCN_CIDR )'
      echo 'This is required'
      exit 50
    else
      echo "Located VCN Network CIDR start as $VCN_CIDR"
    fi
    if [ -z $SERVER_SUBNET_CIDR ]
    then
      echo 'Unable to locate the Server Network CIDR start variable ( SERVER_SUBNET_CIDR )'
      echo 'This is required'
      exit 51
    else
      echo "Located Server Network CIDR start as $SERVER_SUBNET_CIDR"
    fi
    if [ -z $WORKER_SUBNET_CIDR ]
    then
      echo 'Unable to locate the worker Network CIDR start variable ( WORKER_SUBNET_CIDR )'
      echo 'This is required'
      exit 50
    else
      echo "Located worker Network CIDR start as $WORKER_SUBNET_CIDR"
    fi
    
    echo "Creating  K3s cluster lab-$CLUSTER_CONTEXT_NAME-$CLUSTER_NAME"
    echo "Preparing terraform directory"
    SAVED_DIR=`pwd`
    UPDATE_FILE_SCRIPT=$HOME/helidon-kubernetes/setup/common/update-file.sh
    mkdir -p $TF_GIT_BASE
    cd $TF_GIT_BASE
    TF_DIR_BASE=$TF_GIT_BASE/terraform-oci-k3s
    TF_DIR=$TF_DIR_BASE-$CLUSTER_CONTEXT_NAME
	mkdir -p $TF_DIR
	TF_PROVIDER_FILE=k3s-provider.tf
	TF_MODULE_FILE=k3s-module.tf
	TF_OUTPUTS_FILE=k3s-outputs.tf
	TEMP_VERSIONS=versions.tf
    TFP=$TF_DIR/$TF_PROVIDER_FILE
    TFM=$TF_DIR/$TF_MODULE_FILE
    TFO=$TF_DIR/$TF_OUTPUTS_FILE
    TFV=$TF_DIR/$TEMP_VERSIONS
    echo "Configuring terraform"
    cp $TF_SOURCE_CONFIG_DIR/$TF_PROVIDER_FILE $TFP
    cp $TF_SOURCE_CONFIG_DIR/$TF_MODULE_FILE $TFM
    cp $TF_SOURCE_CONFIG_DIR/$TF_OUTPUTS_FILE $TFO
    cp $TF_SOURCE_CONFIG_DIR/$TEMP_VERSIONS $TFV
    cd $TF_DIR
    echo "Processing the provider information"
    echo "Update $TF_PROVIDER_FILE set OCI_REGION"
    bash $UPDATE_FILE_SCRIPT $TFP OCI_REGION "$OCI_REGION"
    echo "Update $TF_PROVIDER_FILE set OCI_HOME_REGION"
    bash $UPDATE_FILE_SCRIPT $TFP OCI_HOME_REGION "$OCI_HOME_REGION"
    echo "Update $TFV set PROVIDER_VERSION"
    bash $UPDATE_FILE_SCRIPT $TFV PROVIDER_VERSION "$PROVIDER_VERSION"
    
    echo "Processing the module general settings"
    echo "Update $TF_MODULE_FILE set K3S_GH_URL"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_GH_URL "$K3S_GH_URL" '^'
    echo "Update $TF_MODULE_FILE to set compartment OCID"
    bash $UPDATE_FILE_SCRIPT $TFM COMPARTMENT_OCID "$COMPARTMENT_OCID"
    echo "Update $TF_MODULE_FILE to set tenancy OCID"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_TENANCY "$OCI_TENANCY"
    echo "Update $TF_MODULE_FILE to set OCI Region"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_REGION "$OCI_REGION"
    echo "Update $TF_MODULE_FILE set OCI_HOME_REGION"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_HOME_REGION "$OCI_HOME_REGION"
    echo "Update $TF_MODULE_FILE set AVAILABILITY_DOMAIN"
    bash $UPDATE_FILE_SCRIPT $TFM AVAILABILITY_DOMAIN "$AVAILABILITY_DOMAIN"
    echo "Update $TF_MODULE_FILE set K3S_ENVIRONMENT"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_ENVIRONMENT "$K3S_ENVIRONMENT"
    echo "Update $TF_MODULE_FILE to set Cluster name"
    bash $UPDATE_FILE_SCRIPT $TFM CLUSTER_NAME "$CLUSTER_NAME_FULL"
    #echo "Update $TF_MODULE_FILE to set Label prefix"
    #bash $UPDATE_FILE_SCRIPT $TFM LABEL_PREFIX "$CLUSTER_NAME_FULL"
    echo "Update $TF_MODULE_FILE to set K3S Kubernetes version"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_KUBERNETES_VERSION "$K3S_KUBERNETES_VERSION"
    
    echo "Updating module networking info"
    echo "Update $TF_MODULE_FILE to set VCN_CIDR"
    bash $UPDATE_FILE_SCRIPT $TFM VCN_CIDR "$VCN_CIDR" ':'
    echo "Update $TF_MODULE_FILE to set SERVER_SUBNET_CIDR"
    bash $UPDATE_FILE_SCRIPT $TFM SERVER_SUBNET_CIDR "$SERVER_SUBNET_CIDR" ':'
    echo "Update $TF_MODULE_FILE to set WORKER_SUBNET_CIDR"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_SUBNET_CIDR "$WORKER_SUBNET_CIDR" ':'
    echo "Update $TF_MODULE_FILE to set PUBLIC_KUBEAPI"
    bash $UPDATE_FILE_SCRIPT $TFM PUBLIC_KUBEAPI "$PUBLIC_KUBEAPI"
    #echo "Update $TF_MODULE_FILE to set datastore type version"
    #bash $UPDATE_FILE_SCRIPT $TFM DATASTORE_TYPE "$DATASTORE_TYPE"
    
    echo "Updating module security info"
    echo "Update $TF_MODULE_FILE to set K3S_CLUSTER_DYNAMIC_GROUP_NAME"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_CLUSTER_DYNAMIC_GROUP_NAME "$K3S_CLUSTER_DYNAMIC_GROUP_NAME"
    echo "Update $TF_MODULE_FILE to set K3S_CLUSTER_POLICY_NAME"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_CLUSTER_POLICY_NAME "$K3S_CLUSTER_POLICY_NAME"
    #echo "Update $TF_MODULE_FILE set VAULT_OCID"
    #bash $UPDATE_FILE_SCRIPT $TFM VAULT_OCID "$VAULT_OCID"
    #echo "Update $TF_MODULE_FILE set VAULT_KEY_OCID"
    #bash $UPDATE_FILE_SCRIPT $TFM VAULT_KEY_OCID "$VAULT_KEY_OCID"
    echo "Update $TF_MODULE_FILE set K3S_SSH_PUBLIC_KEY_PATH"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_SSH_PUBLIC_KEY_PATH "$K3S_SSH_PUBLIC_KEY_PATH" ':'
    echo "Update $TF_MODULE_FILE set K3S_SSH_PRIVATE_KEY_PATH"
    bash $UPDATE_FILE_SCRIPT $TFM K3S_SSH_PRIVATE_KEY_PATH "$K3S_SSH_PRIVATE_KEY_PATH" ':'
    #echo "Update $TF_MODULE_FILE set K3S_TOKEN_SECRET"
    #bash $UPDATE_FILE_SCRIPT $TFM K3S_TOKEN_SECRET "$K3S_TOKEN_SECRET"
    
    echo "Updating module instance info"
    echo "Update $TF_MODULE_FILE set COMPUTE_SHAPE"
    bash $UPDATE_FILE_SCRIPT $TFM COMPUTE_SHAPE "$COMPUTE_SHAPE"
    echo "Update $TF_MODULE_FILE set CONTROL_PLANE_OCPUS"
    bash $UPDATE_FILE_SCRIPT $TFM CONTROL_PLANE_OCPUS "$CONTROL_PLANE_OCPUS"
    echo "Update $TF_MODULE_FILE set CONTROL_PLANE_MEMORY"
    bash $UPDATE_FILE_SCRIPT $TFM CONTROL_PLANE_MEMORY "$CONTROL_PLANE_MEMORY"
    echo "Update $TF_MODULE_FILE set CONTROL_PLANE_EXTRA_NODE_COUNT"
    bash $UPDATE_FILE_SCRIPT $TFM CONTROL_PLANE_EXTRA_NODE_COUNT "$CONTROL_PLANE_EXTRA_NODE_COUNT"
    #echo "Update $TF_MODULE_FILE set CONTROL_PLANE_SHAPE"
    #bash $UPDATE_FILE_SCRIPT $TFM CONTROL_PLANE_BOOT_SIZE "$CONTROL_PLANE_BOOT_SIZE"
    
    echo "Update $TF_MODULE_FILE set WORKER_OCPUS"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_OCPUS "$WORKER_OCPUS"
    echo "Update $TF_MODULE_FILE set WORKER_MEMORY"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_MEMORY "$WORKER_MEMORY"
    echo "Update $TF_MODULE_FILE set WORKER_COUNT"
    bash $UPDATE_FILE_SCRIPT $TFM WORKER_COUNT "$WORKER_COUNT"
    #echo "Update $TF_MODULE_FILE set WORKER_BOOT_SIZE"
    #bash $UPDATE_FILE_SCRIPT $TFM WORKER_BOOT_SIZE "$WORKER_BOOT_SIZE"
    
    #echo "Update $TF_MODULE_FILE set CLUSTER_TZ"
    #bash $UPDATE_FILE_SCRIPT $TFM CLUSTER_TZ $CLUSTER_TZ
    #echo "Update $TF_MODULE_FILE set CREATE_BASION"
    #bash $UPDATE_FILE_SCRIPT $TFM CREATE_BASION $CREATE_BASION
    
    
    echo "Updating module addons info"
    echo "Update $TF_MODULE_FILE set INSTALL_NGINX_INGRESS"
    bash $UPDATE_FILE_SCRIPT $TFM INSTALL_NGINX_INGRESS "$INSTALL_NGINX_INGRESS"
    echo "Update $TF_MODULE_FILE set INSTALL_CERT_MGR"
    bash $UPDATE_FILE_SCRIPT $TFM INSTALL_CERT_MGR "$INSTALL_CERT_MGR"
    echo "Update $TF_MODULE_FILE set INSTALL_NGINX_INGRESS"
    bash $UPDATE_FILE_SCRIPT $TFM CERT_MGR_VERSION "$CERT_MGR_VERSION"
    echo "Update $TF_MODULE_FILE set CERT_MGR_EMAIL"
    bash $UPDATE_FILE_SCRIPT $TFM CERT_MGR_EMAIL "$CERT_MGR_EMAIL"
    echo "Update $TF_MODULE_FILE set INSTALL_LONGHORN"
    bash $UPDATE_FILE_SCRIPT $TFM INSTALL_LONGHORN "$INSTALL_LONGHORN"
    echo "Update $TF_MODULE_FILE set LONGHORN_VERSION"
    bash $UPDATE_FILE_SCRIPT $TFM LONGHORN_VERSION "$LONGHORN_VERSION"
    echo "Update $TF_MODULE_FILE set INSTALL_OCI_CCM"
    bash $UPDATE_FILE_SCRIPT $TFM INSTALL_OCI_CCM "$INSTALL_OCI_CCM"
    echo "Update $TF_MODULE_FILE set INSTALL_NGINX_INGRESS"
    bash $UPDATE_FILE_SCRIPT $TFM OCI_CCM_VERSION "$OCI_CCM_VERSION"
    
   
    
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to create K3S cluster with full name of $CLUSTER_NAME_FULL in $COMPARTMENT_NAME defaulting to $REPLY"
else
  read -p "Do you want to create K3S cluster with full name of $CLUSTER_NAME_FULL in $COMPARTMENT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK stopping K3S cluster creation process"
  exit 1
fi
    
        
    # echo "SHOULD BE Downloading TF versions file, using static version until repo is available"
    # curl --silent https://raw.githubusercontent.com/$K3S_GH_REPO/main/versions.tf --output $TF_DIR/versions.tf
    
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
    K3S_REUSED=false
    echo "Getting cluster netwoking info from terraform"
    K3S_VCN=`terraform output vcn_id |  sed -e 's/"//g'`
    K3S_LB_SUBNET_OCID=`terraform output subnet_ids | grep pub_lb | awk '{print $3}' | sed -e 's/"//g'`
    K3S_WORKER_SUBNET_OCID=`terraform output subnet_ids | grep agent | awk '{print $3}' | sed -e 's/"//g'`
    K3S_LB_NSG_OCID=`terraform output pub_lb_nsg_id | sed -e 's/"//g'`
    K3S_WORKER_NSG_OCID=""
    cd $SAVED_DIR
GETKC=false
if [ "$GETKC" = "true" ]
then
  echo "Getting the kube config file"
  # ensure the context file exists
  KUBECONF_DIR=$HOME/.kube
  KUBECONF_FILE=$KUBECONF_DIR/config
  mkdir -p $KUBECONF_DIR
  touch $KUBECONF_FILE
  # oci ce cluster create-kubeconfig --cluster-id $OKE_OCID --file $KUBECONF_FILE --region $OCI_REGION --token-version 2.0.0  --kube-endpoint PUBLIC_ENDPOINT
  # chmod to be on the safe side sometimes things can have the wront permissions which caused helm to issue warnings
  chmod 600 $KUBECONF_FILE
  echo "Renaming context to $CLUSTER_CONTEXT_NAME"
  # the oci command sets the latest cluster as the default, let's rename it to one so it fits in with the rest of the lab instructions
  CURRENT_CONTEXT=`kubectl config current-context`
  kubectl config rename-context $CURRENT_CONTEXT $CLUSTER_CONTEXT_NAME
fi
  echo "$K3S_REUSED_NAME=false" >> $SETTINGS
  # it's now save to save the OCID's as we've finished
  KUBERNETES_CLUSTER_TYPE_NAME=`bash ../settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME`
  echo "$KUBERNETES_CLUSTER_TYPE_NAME=K3S" >> $SETTINGS
  echo "$K3S_TOKEN_SECRET_NAME=$K3S_TOKEN_SECRET" >> $SETTINGS
  KUBERNETES_VERSION_NAME=`bash ../settings/to-valid-name.sh "KUBERNETES_VERSION_"$CLUSTER_CONTEXT_NAME`
  echo "$KUBERNETES_VERSION_NAME=$K3S_KUBERNETES_VERSION_BASE" >> $SETTINGS

# record some core networking info
CLUSTER_NETWORK_FILE=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME
echo "Saving network information for cluster $CLUSTER_CONTEXT_NAME to $CLUSTER_NETWORK_FILE"
echo "#Network information for cluster $CAPI_CONTEXT_NAME" > $CLUSTER_NETWORK_FILE
echo "export VCN_OCID=$K3S_VCN" >> $CLUSTER_NETWORK_FILE
echo "export LB_SUBNET_OCID=$K3S_LB_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "export WORKER_SUBNET_OCID=$K3S_WORKER_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "export LB_NSG_OCID=$K3S_LB_NSG_OCID" >> $CLUSTER_NETWORK_FILE
echo "export WORKER_NSG_OCID=$K3S_WORKER_NSG_OCID" >> $CLUSTER_NETWORK_FILE