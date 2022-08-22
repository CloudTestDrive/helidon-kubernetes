#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -lt 2 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg name of the tag namespace containing the tag"
    echo "  2nd arg the name of the tag key to retire"
    exit -1
fi
TAG_NS_NAME=$1
TAG_KEY_NAME=$2
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
TAG_NS_OCID_NAME=`bash ./tag-namespace-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_OCID="${!TAG_NS_OCID_NAME}"
if [ -z "$TAG_NS_OCID" ]
then
  echo "Unable to locate OCID setup by these scripts for namespace $TAG_NS_NAME, unable to continue"
  exit 1
fi
TAG_KEY_REUSED_NAME=`bash ./tag-key-get-var-name-reused.sh $TAG_NS_NAME $TAG_KEY_NAME`
TAG_KEY_OCID_NAME=`bash ./tag-key-get-var-name-ocid.sh $TAG_NS_NAME $TAG_KEY_NAME`
TAG_KEY_UNDELETED_NAME=`bash ./tag-key-get-var-name-undeleted.sh $TAG_NS_NAME $TAG_KEY_NAME`
TAG_KEY_REUSED="${!TAG_KEY_REUSED_NAME}"
if [ -z "$TAG_KEY_REUSED" ]
then
  echo "The script can't find any reuse info for the tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME- unsafe to continue"
  exit 1
else
  echo "The script has located reuse info for the tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME- continuing"
fi
if [ "$TAG_KEY_REUSED" = "true" ]
then
  echo "The tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME was reused, will not retire it"
  bash ../delete-from-saved-settings.sh "$TAG_KEY_OCID_NAME"
  bash ../delete-from-saved-settings.sh "$TAG_KEY_REUSED_NAME"
  bash ../delete-from-saved-settings.sh "$TAG_KEY_UNDELETED_NAME"
  exit 0
else
  echo "The the tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME was setup by these scripts - continuing"
fi
echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Retire tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME  (y/n) defaulting to $REPLY"
else
  read -p "Retire tag key $TAG_KEY_NAME in namespace $TAG_NS_NAME  (y/n) ?" REPLY
fi
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then    
  echo "OK, exiting"
  exit 0
else 
  echo "OK, Retiring tag key $TAG_KEY_NAME"
  TAG_KEY_STATE=`oci iam tag retire --tag-name $TAG_KEY_NAME --tag-namespace-id $TAG_NS_OCID  --region $OCI_HOME_REGION | jq -r '.date."lifecycle-state"'`
  echo "Updated tag key state in home region is $TAG_KEY_STATE"
  echo "Waiting for tag key retirement to propogate to local region"
  TAG_RETIRED=false
  for i in `seq 1 10`
  do
    echo "Checking for retirement of tag key test $i for  $TAG_KEY_NAME"
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
    echo "Note that if you want to destroy the key using these scripts then re-activate it and run the dsestroy script"
  else
    echo "Tag key retirement has not propogated in time, stopping"
    exit 1
  fi
fi

bash ../delete-from-saved-settings.sh "$TAG_KEY_OCID_NAME"
bash ../delete-from-saved-settings.sh "$TAG_KEY_REUSED_NAME"
bash ../delete-from-saved-settings.sh "$TAG_KEY_UNDELETED_NAME"