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

if [ -f "$SETTINGS" ]
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
K3S_REUSED_NAME=`bash ../settings/to-valid-name.sh "OKE_REUSED_"$CLUSTER_CONTEXT_NAME`
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
K3S_REUSED="${!K3S_REUSED_NAME}"
if [ -z "$K3S_REUSED" ]
then
  echo "No reuse information for OKE cannot safely continue, you will have to destroy it manually"
  exit 0
fi


CONTEXT_NAME_EXISTS=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME -o name 2>/dev/null`

if [ -z $CONTEXT_NAME_EXISTS ]
then
  echo "Using context name of $CLUSTER_CONTEXT_NAME"
else
  echo "A kubernetes context called $CLUSTER_CONTEXT_NAME does not exist, cannot proceed"
  exit 40
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

TF_DIR=$TF_GIT_BASE/terraform-oci-oke-$CLUSTER_CONTEXT_NAME

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
    echo "Removing context $CLUSTER_CONTEXT_NAME from the local kubernetes configuration"
    CLUSTER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME  --no-headers=true | sed -e 's/*//' | awk '{print $2}'`
    USER_INFO=`kubectl config get-contexts $CLUSTER_CONTEXT_NAME   --no-headers=true  | sed -e 's/*//' | awk '{print $3}'`
    kubectl config delete-user $USER_INFO
    kubectl config delete-cluster $CLUSTER_INFO
    kubectl config delete-context $CLUSTER_CONTEXT_NAME
    echo "The current kubernetes context has been removed, if you have others in your configuration you will need to select it using kubectl configuration set-context context-name"
  else
    echo "no state file, nothing to destroy"
    echo "cannot proceed"
    exit 4
  fi
else
  echo "$TF_DIR not found, nothing we can plan a destruction around"
fi

CLUSTER_NETWORK_FILE=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME
if [ -f $CLUSTER_NETWORK_FILE ]
then
  echo "Removing cluster networking file in $CLUSTER_NETWORK_FILE"
  rm  $CLUSTER_NETWORK_FILE
else
  echo "Cannot locate cluster network file $CLUSTER_NETWORK_FILE unable to clean it up"
fi