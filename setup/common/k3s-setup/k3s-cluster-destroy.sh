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

if [ -f "$SETTINGS" ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
# extract the specific settings for the cluster we're dealing with
#Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
K3S_REUSED_NAME=`bash ../settings/to-valid-name.sh "OKE_REUSED_"$CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
K3S_REUSED="${!K3S_REUSED_NAME}"
if [ -z "$K3S_REUSED" ]
then
  echo "No reuse information for OKE cannot safely continue, you will have to destroy it manually"
  exit 0
fi


    GETKC=false
  
if [ "$GETKC" = "true" ]
then
CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name 2>/dev/null`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Using context name of $CLUSTER_CONTEXT_NAME"
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME does not exist, cannot proceed"
  exit 40
fi
else
  echo "GETKC disabled, won't check for context, this needs to be fixed"
fi
# Where we will put the TF files, don't keep inthe git repo as they get clobbered when we rebuild it
TF_GIT_BASE=$HOME/k3s-terraform

if [ -d $TF_GIT_BASE ]
then
  echo "Located saved terraform state directory"
else
  echo "Unable to locate $TF_GIT_BASE which is where the saved terraform information is held, cannot proceed"
  exit 2
fi

TF_DIR=$TF_GIT_BASE/terraform-oci-k3s-$CLUSTER_CONTEXT_NAME

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
    cd $SAVED_DIR
    rm -rf $TF_DIR
    # can we remove the directory
    REMAINING_TF_CONFIGS=`ls -1 $TF_GIT_BASE | wc -l`
    if [ "$REMAINING_TF_CONFIGS" = 0 ]
    then
      echo "No remaining saved tf configs for OKE, removing the directory"
      rmdir $TF_GIT_BASE
    fi
    KUBERNETES_CLUSTER_TYPE_NAME=`bash ../settings/to-valid-name.sh "KUBERNETES_CLUSTER_TYPE_"$CLUSTER_CONTEXT_NAME`
    bash ../delete-from-saved-settings.sh $KUBERNETES_CLUSTER_TYPE_NAME
    bash ../delete-from-saved-settings.sh $K3S_REUSED_NAME
if [ "$GETKC" = "true" ]
then
    echo "Removing context $CLUSTER_CONTEXT_NAME from the local kubernetes configuration"
    CLUSTER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME  --no-headers=true | sed -e 's/*//' | awk '{print $2}'`
    USER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME   --no-headers=true  | sed -e 's/*//' | awk '{print $3}'`
    kubectl config delete-user $USER_INFO
    kubectl config delete-cluster $CLUSTER_INFO
    kubectl config delete-context $CLUSTER_CONTEXT_NAME
    echo "The current kubernetes context has been removed, if you have others in your configuration you will need to select it using kubectl configuration set-context context-name"
else
  echo "The k3s contest was not obtained, so can't remove it, thsi will need being fixed once Ali gives us a way to get the kube cofig"
fi
  else
    echo "no state file, nothing to destroy"
    echo "cannot proceed"
    exit 4
  fi
else
  echo "$TF_DIR not found, nothing we can plan a destruction around"
  exit 10
fi

# we needed an ssh key, it can now be removed
echo "Removing ssh key"
cd ../ssh-keys
bash ./ssh-key-destroy.sh $HOME/ssh id_rsa_capi_$CLUSTER_CONTEXT_NAME
cd $SAVED_DIR

# the scriots will have created a toke in a vault secret, this needs to be deleted. Unfrotuantely they create int themselves
# so we have to do the work to remove it from the vault and can't use the scritps that do that already as
# they use the OCID

echo "Scheduling deletion of K3S Token secret"
K3S_TOKEN_SECRET_NAME=`bash ../settings/to-valid-name.sh  "K3S_TOKEN_SECRET_NAME_"$CLUSTER_CONTEXT_NAME`
K3S_TOKEN_SECRET="${!K3S_TOKEN_SECRET_NAME}"
if [ -z "$K3S_TOKEN_SECRET" ]
then
  echo "Cannot locate the name of the K3S token secret in the vault, so can't delete it"
else
  echo "Attempting to locate Vault secret $K3S_TOKEN_SECRET"
  K3S_TOKEN_SECRET_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state ACTIVE --name $K3S_TOKEN_SECRET --vault-id $VAULT_OCID | jq -j '.data[0].id'`
  if [ -z "$K3S_TOKEN_SECRET_OCID" ]
  then
    K3S_TOKEN_SECRET_OCID="null"
  fi
  if [ "$K3S_TOKEN_SECRET_OCID" = "null" ]
  then
    echo "Unable to locate an active secret named $K3S_TOKEN_SECRET in the vault"
  else
    echo "Located secret deleting"
    oci vault secret schedule-secret-deletion --secret-id "$K3S_TOKEN_SECRET_OCID"
    RESP=$?
    if [ $RESP -ne 0 ]
    then
      echo "Failure deleting the vault secret $VAULT_SECRET_NAME, exit code is $RESP"
    fi 
  fi
fi

bash ../delete-from-saved-settings.sh "$K3S_REUSED_NAME"
bash ../delete-from-saved-settings.sh "$KUBERNETES_CLUSTER_TYPE_NAME"
bash ../delete-from-saved-settings.sh "$K3S_TOKEN_SECRET_NAME"

CLUSTER_NETWORK_FILE=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME
if [ -f $CLUSTER_NETWORK_FILE ]
then
  echo "Removing cluster networking file in $CLUSTER_NETWORK_FILE"
  rm  $CLUSTER_NETWORK_FILE
else
  echo "Cannot locate cluster network file $CLUSTER_NETWORK_FILE unable to clean it up"
fi