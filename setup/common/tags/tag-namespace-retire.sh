#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg the name of the tag namespace to destroy"
    exit -1
fi
TAG_NS_NAME=$1
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

TAG_NS_REUSED_NAME=`bash ./tag-namespace-get-var-name-reused.sh $TAG_NS_NAME`
TAG_NS_OCID_NAME=`bash ./tag-namespace-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_UNDELETED_NAME=`bash ./tag-namespace-get-var-name-undeleted.sh $TAG_NS_NAME`
TAG_NS_REUSED="${!TAG_NS_REUSED_NAME}"
if [ -z "$TAG_NS_REUSED" ]
then
  echo "The script can't find any reuse info for the tag namespace $TAG_NS_NAME - unsafe to continue"
  exit 1
else
  echo "The script has located reuse info for the tag namespace $TAG_NS_NAME - continuing"
fi
if [ "$TAG_NS_REUSED" = "true" ]
then
  echo "The tag namespace $TAG_NS_NAME was reused, will not retire it"
  bash ../delete-from-saved-settings.sh "$TAG_NS_OCID_NAME"
  bash ../delete-from-saved-settings.sh "$TAG_NS_REUSED_NAME"
  bash ../delete-from-saved-settings.sh "$TAG_NS_UNDELETED_NAME"
  exit 0
else
  echo "The the tag namespace $TAG_NS_NAME was setup by these scripts - continuing"
fi

TAG_NS_OCID="${!TAG_NS_OCID_NAME}"
if [ -z "$TAG_NS_OCID" ]
then
  echo "The script can't find the OCID setting for the tag namespace $TAG_NS_NAME - unsafe to continue"
  exit 1
else
  echo "The script has located the OCID for the tag namespace $TAG_NS_NAME - continuing"
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Retire tag namespace $TAG_NS_OCID  (y/n) defaulting to $REPLY"
else
  read -p "Retire tag namespace $TAG_NS_OCID  (y/n) ?" REPLY
fi
if [[ ! "$REPLY" =~ ^[Yy]$ ]]
then
  echo "OK, Retiring tag namespace $TAG_NS_NAME"
  oci iam tag-namespace retire --tag-namespace-id $TAG_NS_OCID  --region $OCI_HOME_REGION 
  echo "Waiting for tag namespace to retire"
  TAG_RETIRED=false
  for i in `seq 1 10`
  do
    echo "Checking for retirement of tag namespace test $i for  $TAG_NS_NAME"
    COUNT=`oci iam tag-namespace list -c $OCI_TENANCY --include-subcompartments true --all | jq -r "[ .data[] | select ((.\"lifecycle-state\"==\"INACTIVE\") and (.name == \"$TAG_NS_NAME\")) ]| length"`
    if [ "$COUNT" = "1" ]
    then
      echo "tag namespace retirement has propogated"
      TAG_RETIRED=true
      break ;
    fi
    sleep 10
  done
  if [ "$TAG_RETIRED" = "true" ]
  then
    echo "Tag namespace retirement has propogated"
    
  else
    echo "Tag namespace retirement has not propogated in time, stopping"
    exit 1
  fi
else     
  echo "OK, exiting"
  exit 0
fi

bash ../delete-from-saved-settings.sh "$TAG_NS_OCID_NAME"
bash ../delete-from-saved-settings.sh "$TAG_NS_REUSED_NAME"
bash ../delete-from-saved-settings.sh "$TAG_NS_UNDELETED_NAME"