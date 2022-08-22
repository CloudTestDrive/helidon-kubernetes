#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME  requires one argument:"
  echo "the display name of the secret key to destroy"
  exit 1
fi

KEY_NAME=$1
KEY_NAME_CAPS=`bash ../settings/to-valid-name.sh $KEY_NAME`
KEY_ID_NAME=SECRET_KEY_"$KEY_NAME_CAPS"_ID
KEY_VALUE_NAME=SECRET_KEY_"$KEY_NAME_CAPS"

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z "${!KEY_ID_NAME}" ]
then
  echo "$SCRIPT_NAME Key named $KEY_NAME not setup by these scripts, cannot continue"
  exit 0
else
  echo "Key named $KEY_NAME setup by these scripts, deleting"
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

echo "Submitting secret key delete request"
RESP_JSON=`oci iam customer-secret-key delete --user-id "$USER_OCID" --customer-secret-key-id "${!KEY_ID_NAME}" --region $OCI_HOME_REGION --force`

STATUS_FIELD=`echo $RESP_JSON | jq -j ".status"`
if [ -z "$STATUS_FIELD" ]
then
  STATUS_FIELD=null
fi
if [ "$STATUS_FIELD" = "null" ]
then
  echo "Key delete request sucesfully submitted"
else
  echo "Failure status code of $STATUS_FIELD deleting secret key named $KEY_NAME"
fi

bash ../delete-from-saved-settings.sh $KEY_ID_NAME
bash ../delete-from-saved-settings.sh $KEY_VALUE_NAME
