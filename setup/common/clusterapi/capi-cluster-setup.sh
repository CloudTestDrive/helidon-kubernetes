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


if [ -f $CAPI_SETTINGS_FILE ]
  then
    echo "Loading capi settings"
    source $CAPI_SETTINGS_FILE
  else 
    echo "No capi settings file ( $CAPI_SETTINGS_FILE ) cannot continue"
    exit 11
fi

if [ -d $CAPI_DIR ]
then
  echo "Will use $CAPI_DIR as the working directory"
else
  echo "Can't locate the directory $CAPI_DIR have you run the oci-capi-setup.sh script ?"
  exit 4
fi

if [ -z "$USER_INITIALS" ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

CAPI_CONTEXT=capi
if [ $# -gt 0 ]
then
  CAPI_CONTEXT=$1
  CAPI_CONTEXT_NAME="$USER_INITIALS"-"$CAPI_CONTEXT"
  echo "Operating on capi context name $CAPI_CONTEXT_NAME"
else
  CAPI_CONTEXT_NAME="$USER_INITIALS"-"$CAPI_CONTEXT"
  echo "Using default capi context name of $CAPI_CONTEXT_NAME"
fi


KUBE_CONTEXT=one
if [ $# -gt 1 ]
then
  KUBE_CONTEXT=$1
  echo "Operating on kubeconfig context name $KUBE_CONTEXT"
else
  echo "Using default kubeconfig context name of $KUBE_CONTEXT"
fi

CAPI_PROVISIONER_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_PROVISIONER_"$KUBE_CONTEXT"_REUSED"`
CAPI_PROVISIONER_REUSED="${!CAPI_PROVISIONER_REUSED_NAME}"
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


if [ -x "$CLUSTERCTL_PATH" ]
then
  echo "Located clusterctl command"
else
  echo "clusterctl command should be $CLUSTERCTL_PATH but it's not found or not executable, have you run the downloaded-clusterctl.sh script ?"
  exit 2
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
CAPI_CLUSTER_REUSED_NAME=`bash ../settings/to-valid-name.sh CAPI_REUSED_$CAPI_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
CAPI_CLUSTER_REUSED="${!CAPI_CLUSTER_REUSED_NAME}"
if [ -z $CAPI_CLUSTER_REUSED ]
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

export OCI_COMPARTMENT_ID=$COMPARTMENT_OCID
export CAPI_CLUSTER_NAMESPACE=capi-$CAPI_CONTEXT_NAME
export NAMESPACE=$CAPI_CLUSTER_NAMESPACE
export NODE_MACHINE_COUNT=3
export CONTROL_PLANE_MACHINE_COUNT=1
#export OCI_IMAGE_ID
SSH_PUB_FILE="$HOME/ssh/id_rsa_capi_$CAPI_CONTEXT_NAME".pub
export OCI_SSH_KEY=$(cat $SSH_PUB_FILE)

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
CLUSTER_SPECIFIC_CAPI_SETTINGS=$CAPI_CONFIG_DIR/cluster-specific-capi-settings-$CAPI_CONTEXT.sh
if [ -f $CLUSTER_SPECIFIC_CAPI_SETTINGS ]
then
  echo "Located capi cluster specific settings file at $CLUSTER_SPECIFIC_CAPI_SETTINGS"
  echo "Loading capi cluster specific settings"
  source $CLUSTER_SPECIFIC_CAPI_SETTINGS
else
  echo "Cannot locate capi cluster specific settings file $CLUSTER_SPECIFIC_CAPI_SETTINGS, no capi cluster specific overide settings will be applied"
fi

mkdir -p $CLUSTERAPI_YAML_DIR

CAPI_YAML=$CLUSTERAPI_YAML_DIR/capi-cluster-$CAPI_CONTEXT_NAME.yaml

echo "Generating cluster yaml into $CAPI_YAML"
$CLUSTERCTL_PATH generate cluster $CAPI_CONTEXT_NAME --infrastructure oci  --kubeconfig-context $KUBE_CONTEXT --target-namespace $CAPI_CLUSTER_NAMESPACE > $CAPI_YAML

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to apply the generated yaml for the cluster API cluster named $CAPI_CONTEXT_NAME as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME defaulting to $REPLY"
else
  read -p "Do you want to apply the generated yaml for the cluster API cluster named $CAPI_CONTEXT_NAME as the name of the Kubernetes cluster to create or re-use in $COMPARTMENT_NAME (y/n) " REPLY
fi

if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK stopping capi cluster creation process"
  exit 1
fi

echo "Setting up namespace for capi cluster"
NS_COUNT=`kubectl get ns $CAPI_CLUSTER_NAMESPACE --ignore-not-found=true | grep -v NAME | wc -l`
if [ $NS_COUNT = 0 ]
then
  echo "Creating cluster api namespace of $CAPI_CLUSTER_NAMESPACE"
  kubectl create namespace $CAPI_CLUSTER_NAMESPACE
  CAPI_CLUSTER_NAMESPACE_REUSED=false
else
  echo "Cluster cluster namespace $CAPI_NAMESPACE already exists, will reuse it"
  CAPI_CLUSTER_NAMESPACE_REUSED=true
fi
CAPI_CLUSTER_NAMESPACE_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_CLUSTER_NAMESPACE_"$CAPI_CLUSTER_NAMESPACE"_REUSED"`
echo "$CAPI_CLUSTER_NAMESPACE_REUSED_NAME=$CAPI_CLUSTER_NAMESPACE_REUSED" >> $SETTINGS

echo "Applying the generated YAML"

kubectl --context $KUBE_CONTEXT apply -f $CAPI_YAML

echo "Applied the YAML to generate cluster $CAPI_CONTEXT_NAME"

echo "Waiting for capi cluster to be created"
CLUSTER_FOUND=false
LOOP_COUNT=36
LOOP_SLEEP=5
for i in `seq 1 $LOOP_COUNT`
do
  echo "Capi available test $i for capi cluster $CAPI_CONTEXT_NAME"
  CAPI_CLUSTER_COUNT=`kubectl get cluster "$CAPI_CONTEXT_NAME" --namespace "$CAPI_CLUSTER_NAMESPACE" | grep -v PHASE | wc -l`  
  if [ "$CAPI_CLUSTER_COUNT" = "1" ]
  then
    echo "Cluster created"
    CLUSTER_FOUND=true
    break ;
  fi
  sleep $LOOP_SLEEP
done

if [ "$CLUSTER_FOUND" = "false" ]
then
  let DELAY="$LOOP_COUNT*$LOOP_SLEEP"
  echo "Cluster was not created within $DELAY seconds, sorry, cannot continue"
  exit 10
fi
echo "Waiting for capi cluster to be provisioned"
CLUSTER_PROVISIONED=false
LOOP_COUNT=60
LOOP_SLEEP=30
for i in `seq 1 $LOOP_COUNT`
do
  echo "Capi provisioned test $i for capi cluster $CAPI_CONTEXT_NAME"
  CAPI_CLUSTER_COUNT=`kubectl get cluster "$CAPI_CONTEXT_NAME" --namespace "$CAPI_CLUSTER_NAMESPACE" | grep -v PHASE | grep Provisioned | wc -l`  
  if [ "$CAPI_CLUSTER_COUNT" = "1" ]
  then
    echo "Cluster provisioned"
    CLUSTER_PROVISIONED=true
    break ;
  fi
  sleep $LOOP_SLEEP
done

if [ "$CLUSTER_PROVISIONED" = "false" ]
then
  let DELAY="$LOOP_COUNT*$LOOP_SLEEP"
  echo "Cluster was not provisioned within $DELAY seconds, sorry, cannot continue"
  exit 11
fi


CAPI_KUBECONFIG=kubeconfig-capi-$CAPI_CONTEXT_NAME.config
echo "Getting kubeconfig to $CAPI_KUBECONFIG"

$HOME/capi/clusterctl get kubeconfig "$CAPI_CONTEXT_NAME" --namespace "$CAPI_CLUSTER_NAMESPACE" > $CAPI_KUBECONFIG

echo "Waiting for worker node(s) to be provisioned"
WORKERS_PROVISIONED=false
LOOP_COUNT=60
LOOP_SLEEP=30
for i in `seq 1 $LOOP_COUNT`
do
  echo "Capi worker test $i for capi cluster $CAPI_CONTEXT_NAME"
  CAPI_WORKER_CLUSTER_COUNT=`kubectl --kubeconfig=$CAPI_KUBECONFIG get nodes | grep -v control-plane | grep -v ROLES | wc -l`  
  if [ "$CAPI_WORKER_CLUSTER_COUNT" = "$NODE_MACHINE_COUNT" ]
  then
    echo "Cluster worker(s) provisioned"
    WORKERS_PROVISIONED=true
    break ;
  fi
  sleep $LOOP_SLEEP
done

if [ "$WORKERS_PROVISIONED" = "false" ]
then
  let DELAY="$LOOP_COUNT*$LOOP_SLEEP"
  echo "Cluster workers were not provisioned within $DELAY seconds, sorry, cannot continue"
  exit 11
fi

echo "Applying the Calico networking stack using Calico version $CALICO_VERSION"

kubectl --kubeconfig $CAPI_KUBECONFIG apply -f https://docs.projectcalico.org/v$CALICO_VERSION/manifests/calico.yaml

echo "Waiting for control plane and node(s) to be ready"
WORKERS_PROVISIONED=false
LOOP_COUNT=15
LOOP_SLEEP=30
let MACHINE_COUNT="$NODE_MACHINE_COUNT+$CONTROL_PLANE_MACHINE_COUNT"
for i in `seq 1 $LOOP_COUNT`
do
  echo "Capi worker test $i for capi cluster CAPI_CONTEXT_NAME"
  CAPI_WORKER_CLUSTER_COUNT=`kubectl --kubeconfig=$CAPI_KUBECONFIG get nodes | grep -v ROLES | grep Ready | wc -l`  
  if [ "$CAPI_WORKER_CLUSTER_COUNT" = "$MACHINE_COUNT" ]
  then
    echo "Cluster conteol plane and worker(s) in ready state"
    WORKERS_PROVISIONED=true
    break ;
  fi
  sleep $LOOP_SLEEP
done

if [ "$WORKERS_PROVISIONED" = "false" ]
then
  let DELAY="$LOOP_COUNT*$LOOP_SLEEP"
  echo "Cluster workers were not provisioned within $DELAY seconds, sorry, cannot continue"
  exit 11
fi
echo "Locating OCI specific cloud provider settings"

CAPI_OCI_CLUSTER_JSON=`kubectl get ocicluster "$CAPI_CONTEXT_NAME" --namespace "$CAPI_CLUSTER_NAMESPACE" -o json`

CAPI_OCI_VCN_OCID=`echo $CAPI_OCI_CLUSTER_JSON | jq -r ".spec.networkSpec.vcn.id"`
CAPI_OCI_LB_SUBNET_OCID=`echo $CAPI_OCI_CLUSTER_JSON | jq -r '.spec.networkSpec.vcn.subnets[] | select (.name=="service-lb") | .id'`
CAPI_OCI_WORKER_SUBNET_OCID=`echo $CAPI_OCI_CLUSTER_JSON | jq -r '.spec.networkSpec.vcn.subnets[] | select (.name=="worker") | .id'`
CAPI_OCI_LB_NSG_OCID=`echo $CAPI_OCI_CLUSTER_JSON | jq -r '.spec.networkSpec.vcn.networkSecurityGroups[] | select (.name=="service-lb") | .id'`
CAPI_OCI_WORKER_NSG_OCID=`echo $CAPI_OCI_CLUSTER_JSON | jq -r '.spec.networkSpec.vcn.networkSecurityGroups[] | select (.name=="worker") | .id'`

echo "Setting up cloud provider using version $ORACLE_CCM_VERSION"
#use a pre-specified version for now, makes subs easier
CLOUD_PROVIDER_YAML_TEMPLATE="./capi-config/cloud-provider-template-"$ORACLE_CCM_VERSION".yaml"
CLOUD_PROVIDER_YAML="./cloud-provider-"$CAPI_CONTEXT_NAME".yaml"

cp $CLOUD_PROVIDER_YAML_TEMPLATE $CLOUD_PROVIDER_YAML
# this is the origional file download
#curl -L https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/master/manifests/provider-config-instance-principals-example.yaml -o cloud-provider-example.yaml

#modify provider based on outputs
echo "Settting COMPARTMENT_OCID to $COMPARTMENT_OCID"
bash ../update-file.sh $CLOUD_PROVIDER_YAML COMPARTMENT_OCID $COMPARTMENT_OCID
echo "Settting CAPI_OCI_VCN_OCID to $CAPI_OCI_VCN_OCID"
bash ../update-file.sh $CLOUD_PROVIDER_YAML CAPI_OCI_VCN_OCID $CAPI_OCI_VCN_OCID
echo "Settting CAPI_OCI_LB_SUBNET_OCID to $CAPI_OCI_LB_SUBNET_OCID"
bash ../update-file.sh $CLOUD_PROVIDER_YAML CAPI_OCI_LB_SUBNET_OCID $CAPI_OCI_LB_SUBNET_OCID

echo "Creating secret for cloud controller config"
kubectl --kubeconfig=$CAPI_KUBECONFIG create secret generic oci-cloud-controller-manager -n kube-system --from-file=cloud-provider.yaml=$CLOUD_PROVIDER_YAML

echo "Applying the cloud controller manager"
kubectl --kubeconfig=$CAPI_KUBECONFIG apply -f https://github.com/oracle/oci-cloud-controller-manager/releases/download/v$ORACLE_CCM_VERSION/oci-cloud-controller-manager.yaml
echo "Applying the cloud controller manager RBAC"
kubectl --kubeconfig=$CAPI_KUBECONFIG apply -f https://github.com/oracle/oci-cloud-controller-manager/releases/download/v$ORACLE_CCM_VERSION/oci-cloud-controller-manager-rbac.yaml

echo "Updating capi cluster kubeconfig"
CURRENT_CAPI_CONTEXT=`kubectl --kubeconfig=$CAPI_KUBECONFIG config current-context`
kubectl --kubeconfig=$CAPI_KUBECONFIG config rename-context $CURRENT_CAPI_CONTEXT $CAPI_CONTEXT_NAME

echo "Merging capi cluster kube config with main kubeconfig"
# Make a copy of your existing config 
cp $HOME/.kube/config $HOME/.kube/config.bak 
# Merge the two config files together into a new config file 
KUBECONFIG=$HOME/.kube/config:$CAPI_KUBECONFIG kubectl config view --flatten > merged.config 
rm $HOME/.kube/config
# Replace your old config with the new merged config 
mv merged.config $HOME/.kube/config 
chmod 600 $HOME/.kube/config
# remove temp version
rm $CAPI_KUBECONFIG

echo "$CAPI_CLUSTER_REUSED_NAME=false" >> $SETTINGS

# record some core networking info
CLUSTER_NETWORK_FILE=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME
echo "Network information for cluster $CAPI_CONTEXT_NAME" > $CLUSTER_NETWORK_FILE
echo "VCN_OCID=$CAPI_OCI_VCN_OCID" >> $CLUSTER_NETWORK_FILE
echo "LB_SUBNET_OCID=$CAPI_OCI_LB_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "WORKER_SUBNET_OCID=$CAPI_OCI_WORKER_SUBNET_OCID" >> $CLUSTER_NETWORK_FILE
echo "LB_NSG_OCID=$CAPI_OCI_LB_NSG_OCID" >> $CLUSTER_NETWORK_FILE
echo "WORKER_NSG_OCID=$CAPI_OCI_WORKER_NSG_OCID" >> $CLUSTER_NETWORK_FILE

