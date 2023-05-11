#!/bin/bash -f

REQUIRED_ARGS_COUNT=3
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments:"
  echo "the name of the ocir image"
  echo "the version or tag of the ocir image"
  echo "the key name to use (will be auto-prefixed with your initials to match the"
  echo "  other key related scripts and like the other scripts assumse a"
  echo "  single vault is in use here)"
  echo "  if this is not an RSA key then the signing algorythmn will need to be chosen"
  echo "  the most recent enabled version of the key will be used"
  echo "optionally"
  echo "  The signature descrption"
  echo "  the encryption algorythmn to use (by default assums an RSA key and uses SHA_512_RSA_PKCS_PSS) "
  exit -1
fi

OCIR_REPO_NAME=$1
OCIR_IMAGE_TAG=$2
VAULT_KEY_NAME_BASE=$3

if [ $# -ge 4 ]
then
  SIGNING_DESCRIPTION="$4"
else
  SIGNING_DESCRIPTION="Not provided"
fi
if [ $# -ge 5 ]
then
  SIGNING_ALGORITHM="$5"
else
  SIGNING_ALGORITHM="SHA_512_RSA_PKCS_PSS"
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



if [ -z "$COMPARTMENT_OCID" ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi
SAVED_DIR=`pwd`
cd ../vault
if [ -z "$VAULT_OCID" ]
then
  echo "Your vault ocid has not been set, you need to run the vault-setup.sh script before you can run this script"
  exit 1
fi
VAULT_KEY_NAME=`bash ./vault-key-get-key-name.sh $VAULT_KEY_NAME_BASE`
echo "Getting vault key info var name"
VAULT_KEY_OCID_NAME=`bash ./vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`
VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"

if [ -z "$VAULT_KEY_OCID" ]
then
  echo "Your vault key OCID has not been set for key $VAULT_KEY_NAME, you need to run the vault-key-setup.sh script before you can run this script"
  exit 1
else 
  echo "Located OCID for vault key $VAULT_KEY_NAME"
fi
cd $SAVED_DIR
# get the possible reuse and OCID for the devops project itself
echo "Getting var name for OCIR repo $OCIR_REPO_NAME"
OCIR_REPO_OCID_NAME=`bash ./get-ocir-ocid-name.sh $OCIR_REPO_NAME`

OCIR_REPO_OCID="${!OCIR_REPO_OCID_NAME}"

if [ -z $OCIR_REPO_OCID ]
then
  echo "No OCID found for repo names $OCIR_REPO_NAME cannot continue"
  exit 3
else
  echo "Located OCID for Repo $OCIR_REPO_NAME"
fi
echo "Looking for image $OCIR_REPO_NAME"":""$OCIR_IMAGE_TAG ocid"
IMAGE_VERSION_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name "$OCIR_REPO_NAME"":""$OCIR_IMAGE_TAG" | jq -j ".data.items[0].id"`
if [ -z "$IMAGE_VERSION_OCID" ]
then
  echo "Cannot locate image $OCIR_REPO_NAME with tag $OCIR_IMAGE_TAG"
  exit 6
else
  echo "Located image OCID for $OCIR_REPO_NAME"":""$OCIR_IMAGE_TAG"
fi

echo "Getting vault endpoint for vault OCID $VAULT_OCID"
VAULT_ENDPOINT=`oci kms management vault get --vault-id $VAULT_OCID | jq -j '.data."management-endpoint"'`
if [ -z "$VAULT_ENDPOINT" ]
then
  echo "Cannot locate endpoint for vault"
  exit 7
else
  echo "Located endpoint for the vault"
fi


echo "Getting vault key info"

KEY_VERSION_OCID=`oci kms management key-version list --key-id "$VAULT_KEY_OCID" --endpoint "$VAULT_ENDPOINT" --all --sort-by TIMECREATED | jq -j "[ .data[] | select ( .\"lifecycle-state\" == \"ENABLED\" ) ] | first | .id"`
if [ -z "$KEY_VERSION_OCID" ]
then
  echo "Can't locate a enabled key version for key $VAULT_KEY_NAME, cannot continue"
  exit 4 
else
  echo "Located an enabled key version for key $VAULT_KEY_NAME"
fi

echo "Requesting signing of image $OCIR_REPO_NAME"":""$OCIR_IMAGE_TAG using key $VAULT_KEY_NAME and algorythmn $SIGNING_ALGORITHM"
IMAGE_SIGN_OCID=`oci artifacts container image-signature sign-upload --compartment-id "$COMPARTMENT_OCID" --kms-key-id "$VAULT_KEY_OCID" --kms-key-version-id "$KEY_VERSION_OCID" --signing-algorithm "$SIGNING_ALGORITHM" --image-id "$IMAGE_VERSION_OCID" --description "$SIGNING_DESCRIPTION" | grep '^ID:' | sed -e 's/^ID: //'`

if [ -z "$IMAGE_SIGN_OCID" ]
then
  echo "No id in result, operation probabaly failed"
  exit 10
else
  echo "Image signing returned ID, image was signed"
fi