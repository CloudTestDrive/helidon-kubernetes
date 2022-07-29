#!/bin/bash -f
if [ $# -lt 1 ]
then
  echo "The secret key setup script requires ont arguments:"
  echo "the display name of the secret key to create"
  exit 1
fi

KEY_NAME=$1
KEY_NAME_CAPS=`bash ../settings/to-valid-name.sh $KEY_NAME`
KEY_ID_NAME=SECRET_KEY_"$KEY_NAME_CAPS"_ID
KEY_VALUE_NAME=SECRET_KEY_"$KEY_NAME_CAPS"

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

if [ -z "${!KEY_ID_NAME}" ]
then
  echo "Key named $KEY_NAME not setup by these scripts, continuing"
else
  echo "Key named $KEY_NAME already setup by these scripts, cannot continue"
  exit 0
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

echo "Creating secret key"
KEY_JSON=`oci iam customer-secret-key create --user-id $USER_OCID --display-name "$KEY_NAME" --region $OCI_HOME_REGION`

STATUS_FIELD=`echo $KEY_JSON | jq -j ".status"`
if [ "$STATUS_FIELD" = "null" ]
then
  echo "Key created, extracting data"
else
  echo "Status code of $STATUS_FIELD creating secret key names $KEY_NAME, can't continue"
  exit 1
fi

KEY_VALUE=`echo $KEY_JSON | jq -j ".data.key"`
KEY_ID=`echo $KEY_JSON | jq -j ".data.id"`

echo "Waiting for secret key to propogate"
FOUND=false
for i in `seq 1 10`
do
  echo "Propogate test $i for secret key $KEY_NAME"
  STATE=`oci iam customer-secret-key list --user-id $USER_OCID | jq -r ".data[] | select (.id=\"$KEY_ID\") | .\"lifecycle-state\""`
  if [ -z "$STATE" ]
  then
    STATE=NOT_FOUND
  fi
  if [ "$STATE" = "ACTIVE" ]
  then
    echo "Secret key has propogated"
    FOUND=true
    break ;
  fi
  sleep 10
done
if [ "$FOUND" = "true" ]
then
  echo $KEY_ID_NAME=$KEY_ID >> $SETTINGS
  echo $KEY_VALUE_NAME=$KEY_VALUE >> $SETTINGS
  exit 0
else
  echo "Secret key has not propogated in time, stopping"
  exit 3
fi