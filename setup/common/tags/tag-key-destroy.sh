#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -le 2 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg name of the tag namespace containing the tag"
    echo "  2nd arg the name of the tag key to destroy"
    exit -1
fi
TAG_NS_NAME=$1
TAK_KEY_NAME=$2
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings"
fi
echo "Destroying the tag-key can take a long time, potentially up to 48 hours during"
echo "which time you will not be able to re-create a new tag-key with the same name."
echo "This means that any labs you are running which rely on the key cannot be run."
echo "Unless you really, really need to destroy the tag key we recommend that you "
echo "just ignore it as it doesn't use resources"
read -p "Do you want to proceed with deleting the tag key (y/n) ?" REPLY
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, Retiring and then deleting the tag key $TAG_NS_NAME"
else
  echo "Good decision, exiting"
  exit 0
fi

TAG_NS_OCID_NAME=`bash ./tag-namespace-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_OCID="${!TAG_NS_OCID_NAME}"
if [ -z "$TAG_NS_OCID" ]
then
  echo "Unable to locate OCID setup by these scripts fo t tag ns $TAG_NS_NAME, unable to continue"
  exit 1
fi
TAG_NS_REUSED_NAME=`bash ./tag-key-get-var-name-reused.sh $TAG_NS_NAME`
TAG_NS_OCID_NAME=`bash ./tag-key-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_UNDELTED_NAME=`bash ./tag-key-get-var-name-undeleted.sh $TAG_NS_NAME`
TAG_NS_REUSED="${!TAG_NS_REUSED_NAME}"
if [ -z "$TAG_NS_REUSED" ]
then
  echo "The script can't find any reuse info for the tag key $TAG_NS_NAME - unsafe to continue"
  exit 1
else
  echo "The script has located reuse info for the tag key $TAG_NS_NAME - continuing"
fi
if [ "$TAG_NS_REUSED" = "true"]
then
  echo "The tag key $TAG_NS_NAME was reused, will not delete it"
  exit 0
else
  echo "The the tag key $TAG_NS_NAME was setup by these scripts - continuing"
fi

TAG_NS_OCID="${!TAG_NS_OCID_NAME}"
if [ -z "$TAG_NS_OCID" ]
then
  echo "The script can't find the OCID setting for the tag key $TAG_NS_NAME - unsafe to continue"
  exit 1
else
  echo "The script has located the OCID for the tag key $TAG_NS_NAME - continuing"
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Retire tag key $TAG_NS_OCID  (y/n) defaulting to $REPLY"
else
  read -p "Retire tag key $TAG_NS_OCID  (y/n) ?" REPLY
fi
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, Retire tag key $TAG_NS_NAME"
  oci iam tag retire --tag-name $TAG_KEY_NAME --tag-namespace-id $TAG_NS_OCID  --region $OCI_HOME_REGION 
  echo "Waiting for tag key to retire"
  TAG_RETIRED=false
  for i in `seq 1 10`
  do
    echo "Checking for retirement of tag key test $i for  $TAG_NS_NAME"
    COUNT=`oci iam tag list --tag-namespace-id $TAG_NS_OCID  --all | jq -r "[ .data[] | select ((.\"lifecycle-state\"==\"INACTIVE\") and (.name == \"$TAG_KEY_NAME\")) ]| length"`
    if [ "$COUNT" = "1" ]
    then
      echo "tag key retirement has propogated"
      TAG_RETIRED=true
      break ;
    fi
    sleep 10
  done
  if [ "$TAG_RETIRED" = "true" ]
  then
    echo "Tag key retirement has propogated"
  else
    echo "Tag key retirement has not propogated in time, stopping"
    exit 1
  fi
else     
  echo "OK, exiting"
  exit 0
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Delete tag key $TAG_NS_OCID and tags (y/n) defaulting to $REPLY"
else
  read -p "Delete tag key $TAG_NS_OCID and tags  (y/n) ?" REPLY
fi
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, Deleting tag key $TAG_NS_OCID and tags"
  oci iam tag delete --ta--tag-namespace-id $TAG_NS_OCID   --region $OCI_HOME_REGION
  echo "Tag key delete triggered, this may take a while"
else     
  echo "OK, not  deleting"
fi


bash ../delete-from-saved-settings.sh "$TAG_NS_OCID_NAME"
bash ../delete-from-saved-settings.sh "$TAG_NS_REUSED_NAME"
bash ../delete-from-saved-settings.sh "$TAG_NS_UNDELETED_NAME"