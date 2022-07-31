#!/bin/bash -f
SCRIPT_NAME=`basename $0`

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME Missing arguments you must provide:"
  echo "  1st argument - name of the secret key that was created"
  echo "Optionally"
  echo "  2nd argument - the context of the cluster to deploy into - defaults to one if not provided"
  exit 1
fi
KEY_NAME=$1

CLUSTER_CONTEXT_NAME=one
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
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

if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run this script"
  exit 1
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

echo "Checking for existing bucket in the wrong compartment"

BUCKET_NAME=`echo "LOGGING_FLUENTD_""$USER_INITIALS""_""$CLUSTER_CONTEXT_NAME" | tr [:lower:] [:upper:]`

echo "Getting Object storage namespace"
OOSS_NAMESPACE=`oci os  ns get | jq -r ".data"`

S3_COMPAT_OCID=`oci os  ns get-metadata  --namespace-name $OOSS_NAMESPACE | jq -r '.data."default-s3-compartment-id"'`
S3_COMPARTMENT_NAME=`oci iam compartment get --compartment-id $S3_COMPAT_OCID | jq -r ".data.name"`

SAVED_DIR=`pwd`
cd $HOME/helidon-kubernetes/setup/common/object-storage
# check if the bucket is in the S3 compartment, if already exists and not there then can't run
bash ./check-if-bucket-is-in-s3-compartment.sh $BUCKET_NAME
RESP=$?
# returns 1 if the bucked exists but itn's in the S3 compartment
if [ "$RESP" = 1 ]
then
  echo "Sorry, but bucket $BUCKET_NAME already exists but not in the S3 compatibility compartment of $S3_COMPARTMENT_NAME"
  exit 1
fi

bash ./object-storage-bucket-setup.sh $BUCKET_NAME standard $S3_COMPAT_OCID

cd $SAVED_DIR


KEY_NAME_CAPS=`bash ../../common/settings/to-valid-name.sh $KEY_NAME`
KEY_ID_NAME=SECRET_KEY_"$KEY_NAME_CAPS"_ID
KEY_VALUE_NAME=SECRET_KEY_"$KEY_NAME_CAPS"
KEY_VALUE=${!KEY_VALUE_NAME}
KEY_ACCESS_ID=${!KEY_ID_NAME}

if [ -z "$KEY_ACCESS_ID" ]
then
  echo "Secrect key was not created, stopping"
  exit 1
fi

echo "Collecting information to setup config map"
 
echo "Namespace is $OOSS_NAMESPACE"

OOSS_URL="https://$OOSS_NAMESPACE.compat.objectstorage.$OCI_REGION.oraclecloud.com"
echo "OOSS_URL is $OOSS_URL"

echo "S3 compat compartment is $S3_COMPARTMENT_NAME"

echo "Creating logging namespace in cluster $CLUSTER_CONTEXT_NAME"

kubectl create namespace logging --context $CLUSTER_CONTEXT_NAME


LOGGING_MODULE_DIR=$HOME/helidon-kubernetes/management/logging

S3_CONFIGURED_YAML=fluentd-s3-configmap-$CLUSTER_CONTEXT_NAME.yaml
echo "Configuring yaml file $S3_CONFIGURED_YAML"
cp $LOGGING_MODULE_DIR/fluentd-s3-configmap.yaml ./$S3_CONFIGURED_YAML

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

echo "Installing OCI OOSS based S3 config map in cluster $CLUSTER_CONTEXT_NAME"
kubectl apply -f $S3_CONFIGURED_YAML --context $CLUSTER_CONTEXT_NAME

echo "Installing the genmeral OSS basec config map in cluster $CLUSTER_CONTEXT_NAME"
kubectl apply -f $LOGGING_MODULE_DIR/fluentd-to-ooss-configmap.yaml --context $CLUSTER_CONTEXT_NAME

echo "Installing fluentd daemon set in cluster $CLUSTER_CONTEXT_NAME"
kubectl apply -f $LOGGING_MODULE_DIR/fluentd-daemonset-ooss-rbac.yaml --context $CLUSTER_CONTEXT_NAME

