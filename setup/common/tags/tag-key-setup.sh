#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -lt 3 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg the name of the tag namespace to create the tag in"
    echo "  2nd arg the name of the tag to create"
    echo "  3rd arg the description of the tag"
    echo "Optional"
    echo "  4th and subsequent args are a list of allowed values for the tag, if missing then the tag can have any value"
    exit -1
fi
TAG_NS_NAME=$1
TAG_KEY_NAME=$2
TAG_DESCRIPTION=$3
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

# try and see if we know about this key already

TAG_KEY_REUSED_NAME=`bash ./tag-key-get-var-name-ocid.sh $TAG_NS_NAME $TAG_KEY_NAME`
TAG_KEY_REUSED="${!TAG_KEY_REUSED_NAME}"

if [ -z "$TAG_KEY_REUSED" ]
then
  echo "No reuse information for tag key $TAG_KEY_NAME in tag namespace $TAG_NS_NAME continuing"
else
  echo "These scripts have already setup tag key $TAG_KEY_NAME in tag namespace $TAG_NS_NAME It is assumed to have the correct settings, exiting"
  exit 0
fi

TAG_NS_OCID_NAME=`bash ./tag-namespace-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_OCID="${!TAG_NS_OCID_NAME}"
if [ -z "$TAG_NS_OCID" ]
then
  echo "Cannot locate OCID for tag namespace $TAG_NS_NAME have you run the tag-namespace-setup.sh script for this tag namespace ? Cannot continue"
  exit 1
else
  echo "Located tag namespace $TAG_NS_NAME setup by these scripts"
fi
# work out what the validation should look like
VALUES_START_ARG=4
if [ $# -ge $VALUES_START_ARG ]
then
  VALIDATOR_TYPE=ENUM
  VALIDATOR_VALUES='['
  for i in `seq $VALUES_START_ARG $#`
  do
    if [ $i -gt $VALUES_START_ARG ]
    then
      VALIDATOR_VALUES="$VALIDATOR_VALUES"","
    fi
    VALIDATOR_VALUES="$VALIDATOR_VALUES""\"${!i}\""
  done
  VALIDATOR_VALUES="$VALIDATOR_VALUES"']'
  VALIDATOR_STRING="{\"validatorType\": \"ENUM\", \"values\": $VALIDATOR_VALUES}"
else
  VALIDATOR_TYPE=DEFAULT
  VALIDATOR_STRING="{\"validatorType\": \"DEFAULT\"}"
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

TAG_KEY_JSON=`oci iam tag get --tag-namespace-id $TAG_NS_OCID --tag-name $TAG_KEY_NAME  --region $OCI_HOME_REGION 2>&1`
TAG_KEY_OCID=`echo "$TAG_KEY_JSON" | grep -v '^ServiceError:' | jq -r '.data.id'`
if [ -z "$TAG_KEY_OCID" ]
then
  TAG_KEY_OCID="null"
fi
TAG_KEY_UNDELETED=false
if [ "$TAG_KEY_OCID" = "null" ]
then
  echo "No existing tag key $TAG_KEY_NAME found in tag namespace $TAG_NS_NAME creating"
  TAG_KEY_OCID=`oci iam tag create --name "$TAG_KEY_NAME" --description "$TAG_KEY_DESCRIPTION" --tag-namespace-id "$TAG_NS_OCID" --validator "$VALIDATOR_STRING" --wait-for-state ACTIVE --region $OCI_HOME_REGION | jq -r '.data.id'`
else
  echo "Found existing tag key $TAG_KEY_NAME in tag namespace $TAG_NS_NAME checking it's state"
  TAG_KEY_STATE=`echo "$TAG_KEY_JSON" | jq -r '.data.id'`
  if [ "$TAG_KEY_STATE" = "ACTIVE" ]
  then
    echo "Existing key is active, assuming it meets your needs and reusing it"
    TAG_KEY_REUSED=true
  elif [ "$TAG_KEY_STATE" = "INACTIVE" ]
  then
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, Existing tag key $TAG_KEY_NAME in tag namespace $TAG_NS_NAME is inactive, do you want to reactivate it (y/n) ? defaulting to $REPLY"
    else
      read -p "Existing tag key $TAG_KEY_NAME in tag namespace $TAG_NS_NAME is inactive, do you want to reactivate it (y/n) ? This will assume that it meets your needs, if not you will have to delete it and recreate ?" REPLY
    fi
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]
    then
      echo "OK, exiting, you may want to delete the tag key (this can take some time) and the run this script again)"
      exit 10
    else     
      echo "OK, reactivating tag"
      UPDATED_STATE=`oci iam tag reactivate --tag-namespace-id $TAG_NS_OCID --tag-name $TAG_KEY_NAME --region $OCI_HOME_REGION | jq -r '.data."lifecycle-state"'`
      echo "Updated state is now $UPDATED_STATE"
      TAG_KEY_UNDELETED=true
    fi
  else
    echo "Existing key is in an intrasit state -  $TAG_KEY_STATE , this can take a long time to achieve to a stable state, script will exit, please try again later"
    exit 100
  fi
fi