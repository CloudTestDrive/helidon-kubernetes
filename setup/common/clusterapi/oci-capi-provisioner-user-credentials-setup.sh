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

if [ -z "$USER_OCID" ]
then
  echo 'No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
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

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
fi
echo "Management cluster context is $CLUSTER_CONTEXT_NAME"

CAPI_PROVISIONER_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_PROVISIONER_"$CLUSTER_CONTEXT_NAME"_REUSED"`
CAPI_PROVISIONER_REUSED="${!CAPI_PROVISIONER_REUSED_NAME}"
if [ -z "$CAPI_PROVISIONER_REUSED" ]
then
  echo "No reuse information for CAPI in cluster $CLUSTER_CONTEXT_NAME proceeding"
else
  echo "Located CAPI reuse information for cluster $CLUSTER_CONTEXT_NAME, reusing existing deployment"
  exit 1
fi

# do we have a fingerprint and key location ?
KEY_NAME=capi
SSH_DIR_NAME=ssh
SSH_DIR=$HOME/$SSH_DIR_NAME
SSH_KEY_FILE_BASE=id_rsa_$KEY_NAME
SSH_PRIVATE_KEY_FILE=$SSH_DIR/$SSH_KEY_FILE_BASE
if [ -f "$SSH_PRIVATE_KEY_FILE" ]
then
  echo "Located ssh private key for $KEY_NAME"
else
  echo "Cannot locate the ssh key file for $KEY_NAME, this should be $SSH_PRIVATE_KEY_FILE, has"
  echo "the oci-capi-api-key-setup.sh script been run ?"
  exit 3
fi
API_KEY_FINGERPRINT_NAME=`bash ../api-keys/get-key-fingerprint-var-name.sh "$KEY_NAME" "$USER_INITIALS"`
API_KEY_FINGERPRINT="${!API_KEY_FINGERPRINT_NAME}"
if [ -z "$API_KEY_FINGERPRINT" ]
then
  echo "Cannot locate API fingerprint, this should be in variable $API_KEY_FINGERPRINT_NAME, set"
  echo "in file $SETTINGS, has the oci-capi-api-key-setup.sh script been run ?"
  exit 2
fi


# if the CAPI_DIR already exists then record as being reused
if [ -d "$CAPI_DIR" ]
then
  CAPI_PROVISIONER_REUSED=true
else
  CAPI_PROVISIONER_REUSED=false
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to install the cluster api provider into kubernetes cluster $CLUSTER_CONTEXT_NAME defaulting to $REPLY"
else
  read -p "Do you want to install the cluster api provider into kubernetes cluster $CLUSTER_CONTEXT_NAME (y/n) " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not installing"
  exit 1
fi
ORIG_K8S_CONTEXT=`kubectl config current-context`
# switch to our specified context
kubectl config use-context $CLUSTER_CONTEXT_NAME
if [ $? = 0 ]
then
  echo "Switch so context $CLUSTER_CONTEXT_NAME"
else
  echo "Unable to find kubernetes context $CURRENT_CONTEXT_NAME, cannot continue"
  exit 1
fi

echo "Setting up namespace for capi"
NS_COUNT=`kubectl get ns $CAPI_NAMESPACE --ignore-not-found=true | grep -v NAME | wc -l`
if [ $NS_COUNT = 0 ]
then
  echo "Creating cluster api namespace of $CAPI_NAMESPACE"
  kubectl create namespace $CAPI_NAMESPACE
  CAPI_NAMESPACE_REUSED=false
else
  echo "Cluster namespace $CAPI_NAMESPACE already exists, will reuse it"
  CAPI_NAMESPACE_REUSED=true
fi
CAPI_NAMESPACE_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_NAMESPACE_REUSED_"$CLUSTER_CONTEXT_NAME"_REUSED"`

echo "$CAPI_NAMESPACE_REUSED_NAME=$CAPI_NAMESPACE_REUSED" >> $SETTINGS

echo "Installing cluster API provisioner into cluster $CLUSTER_CONTEXT_NAME"

# create the cluster api directory
mkdir -p $CAPI_DIR
cat <<EOF > $HOME/.cluster-api/clusterctl.yaml
providers:
  - name: oci
    url: https://github.com/oracle/cluster-api-provider-oci/releases/v$ORACLE_CAPI_VERSION/infrastructure-components.yaml
    type: InfrastructureProvider
EOF

# record the status of the setr manager ns
CERT_MGR_NS=cert-manager
echo "Checking for pre-existing $CERT_MGR_NS namespace"
CERT_MGR_NS_COUNT=`kubectl get ns | grep "$CERT_MGR_NS" | wc -l`
if [ "$CERT_MGR_NS_COUNT" = 0 ]
then
  echo "No pre-existing namespace $CERT_MGR_NS"
  CERT_MGR_NS_REUSED=false
else
  echo "Located pre-existing namespace $CERT_MGR_NS"
  CERT_MGR_NS_REUSED=true
fi
CERT_MGR_NS_REUSED_NAME=`bash ../settings/to-valid-name.sh "CAPI_CERT_MANAGER_NS_"$CLUSTER_CONTEXT_NAME"_REUSED"`
echo "$CERT_MGR_NS_REUSED_NAME=$CERT_MGR_NS_REUSED" >> $SETTINGS

# setup to use user credentials - ideally instance ones woudl be best, but for now ...
export OCI_TENANCY_ID=$OCI_TENANCY
export OCI_USER_ID=$USER_OCID
export OCI_CREDENTIALS_FINGERPRINT=$API_KEY_FINGERPRINT
# OK this is redundant, and may not even work
#export OCI_REGION=$OCI_REGION
export OCI_TENANCY_ID_B64="$(echo -n "$OCI_TENANCY_ID" | base64 | tr -d '\n')"
export OCI_CREDENTIALS_FINGERPRINT_B64="$(echo -n "$OCI_CREDENTIALS_FINGERPRINT" | base64 | tr -d '\n')"
export OCI_USER_ID_B64="$(echo -n "$OCI_USER_ID" | base64 | tr -d '\n')"
export OCI_REGION_B64="$(echo -n "$OCI_REGION" | base64 | tr -d '\n')"
export OCI_CREDENTIALS_KEY_B64=$(base64 < $SSH_PRIVATE_KEY_FILE | tr -d '\n')
   

$CLUSTERCTL_PATH init --infrastructure oci --target-namespace $CAPI_NAMESPACE

# revert to the origional context
kubectl config use-context $ORIG_K8S_CONTEXT

echo "Reverted to context $ORIG_K8S_CONTEXT"

echo "$CAPI_PROVISIONER_REUSED_NAME=$CAPI_PROVISIONER_REUSED" >> $SETTINGS