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


source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "This script is currently in place to support testing purposes, it will not do"
echo "much if any error checking / handling, and assumes that you dont have anything"
echo "already in place"
read -p "Proceed on this basis (y/n) ?" REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, stopping"
  exit 0
else
  echo "OK, continuing"
fi

echo "Creating labs secret key"
SAVE_DIR=`pwd`
cd $HOME/helidon-kubernetes/setup/common/secret-keys
KEY_NAME="LoggingLabsTestKey"
KEY_NAME_CAPS=`bash ../settings/to-valid-name.sh $KEY_NAME`
KEY_ID_NAME=SECRET_KEY_"$KEY_NAME_CAPS"_ID
KEY_VALUE_NAME=SECRET_KEY_"$KEY_NAME_CAPS"

bash ./secret-key-setup.sh $KEY_NAME

cd $HOME/helidon-kubernetes/management/logging


# the settings will have been updated with the key name 
source $SETTINGS

KEY_VALUE=${!KEY_VALUE_NAME}
KEY_ACCESS_ID=${!KEY_ID_NAME}

if [ -z "$KEY_ACCESS_ID" ]
then
  echo "Key not created, stopping"
  exit 1
fi

echo "Collating information to setup config map"
 
echo "Getting Object storage namespace"
OOSS_NAMESPACE=`oci os  ns get | jq -r ".data"`
echo "Namespace is $OOSS_NAMESPACE"

OOSS_URL="https://$OOSS_NAMESPACE.compat.objectstorage.$OCI_REGION.oraclecloud.com"
echo "OOSS_URL is $OOSS_URL"

echo "Getting Object storage S3 compat compartment"
S3_COMPAT_OCID=`oci os  ns get-metadata  --namespace-name $OOSS_NAMESPACE | jq -r '.data."default-s3-compartment-id"'`
S3_COMPARTMENT_NAME=`oci iam compartment get --compartment-id $S3_COMPAT_OCID | jq -r ".data.name"`
echo "S3 compat compartment is $S3_COMPARTMENT_NAME"

STORAGE_TIER=Standard
BUCKET_NAME=`echo "$USER_INITIALS"_FLUENTD | tr [:lower:] [:upper:]`

if [ -z "$LOGGING_OOSS_BUCKET_NAME" ]
then
  echo "Creating the storage bucket named $BUCKET_NAME in tier $STORAGE_TIER"
  LOGGING_LAB_BUCKET_OCID=`oci os bucket create --compartment-id $S3_COMPAT_OCID  --name $BUCKET_NAME --storage-tier $STORAGE_TIER | jq -r '.data.id'`
  echo "LOGGING_OOSS_BUCKET_NAME=$BUCKET_NAME">> $SETTINGS
else 
  echo "Reusing bucket ID $LOGGING_OOSS_BUCKET_NAME"
fi

LOGGING_MODULE_DIR=$HOME/helidon-kubernetes/management/logging

cd $HOME/helidon-kubernetes/setup/common

echo "Creating logging namespace"

kubectl create namespace logging


S3_CONFIGURED_YAML=$LOGGING_MODULE_DIR/fluentd-s3-configmap-configured.yaml
echo "Configuring yaml file $S3_CONFIGURED_YAML"
cp $LOGGING_MODULE_DIR/fluentd-s3-configmap.yaml $S3_CONFIGURED_YAML

echo "Secret key value"
bash update-file.sh $S3_CONFIGURED_YAML YOUR_ACCESS_SECRET $KEY_VALUE ^
echo "Secret key id"
bash update-file.sh $S3_CONFIGURED_YAML YOUR_ACCESS_KEY $KEY_ACCESS_ID ^
echo "Storage bucket"
bash update-file.sh $S3_CONFIGURED_YAML YOUR_BUCKET_NAME $BUCKET_NAME ^
echo "Region"
bash update-file.sh $S3_CONFIGURED_YAML YOUR_REGION $OCI_REGION ^
echo "Storage endpoint URL"
bash update-file.sh $S3_CONFIGURED_YAML YOUR_STORAGE_ENDPOINT $OOSS_URL ^

echo "Installing OCI OOSS based S3 config map"
kubectl apply -f $S3_CONFIGURED_YAML

echo "Installing the genmeral OSS basec config map"
kubectl apply -f $LOGGING_MODULE_DIR/fluentd-to-ooss-configmap.yaml

echo "Installing fluentd daemon set"
kubectl apply -f $LOGGING_MODULE_DIR/fluentd-daemonset-ooss-rbac.yaml

