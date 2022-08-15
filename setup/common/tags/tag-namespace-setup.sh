#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg the name of the tag namespace to create"
    echo "Optional"
    echo "  2nd arg the OCID of the compartment to install into - defaults to the OCID in the settings COMPARTMENT_OCID variable"
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

if [ $# -ge 2 ]
then
  TAG_NS_COMPARTMENT_OCID="$2"
  echo "$SCRIPT_NAME Operating on provided tag namespace comparement OCID $TAG_NS_COMPARTMENT_OCID"
else
  if [ -z "$COMPARTMENT_OCID" ]
  then
    echo "You need to provide a compartment to create the tag namespace in, COMPARTMENT_OCID is not set, have you run the compartment-setup script ?"
    exit 1 ;
  else
    TAG_NS_COMPARTMENT_OCID="$COMPARTMENT_OCID"
  echo "$SCRIPT_NAME Creating tag namespace in default comparement OCID $TAG_NS_COMPARTMENT_OCID"
  fi
fi
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

TAG_NS_REUSED_NAME=`bash ./tag-namespace-get-var-name-reused.sh $TAG_NS_NAME`
TAG_NS_OCID_NAME=`bash ./tag-namespace-get-var-name-ocid.sh $TAG_NS_NAME`
TAG_NS_UNDELETED_NAME=`bash ./tag-namespace-get-var-name-undeleted.sh $TAG_NS_NAME`
TAG_NS_REUSED="${!TAG_NS_REUSED_NAME}"
TAG_NS_UNDELETED=false
if [ -z "$TAG_NS_REUSED" ]
then
  echo "The script hasn't setup the tag namespace $TAG_NS_NAME - continuing"
else
  echo "The script has already setup the tag namespace $TAG_NS_NAME - reusing it"
  exit 0
fi

echo "Locating home region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`
OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`
echo "Checking for inactive TAG namespace"

INACTIVE_TAG_NS_OCID=`oci iam tag-namespace list -c $OCI_TENANCY --include-subcompartments true --all --region $OCI_HOME_REGION | jq -r ".data[] | select ((.name == \"$TAG_NS_NAME\") and (.\"lifecycle-state\" == \"INACTIVE\")) | .id"`
if [ -z "$INACTIVE_TAG_NS_OCID" ]
then
  echo "No inactive tag namespace called $TAG_NS_NAME found, continuing"
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Found an inactive tag namespace, reactivate it (y/n) ? (you can't create a replaement unless this inactive one is destroyed) defaulting to $REPLY"
  else
    read -p "Found an inactive tag namespace, reactivate it (y/n) ? (you can't create a replaement unless this inactive one is destroyed) ?" REPLY
  fi
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]
  then
    echo "OK, exiting, take recovery actions, but be aware that you cannot reuse a tag namespace name if there is any other active or inactive namespaxe with that name already"
    exit 10
  else     
    echo "OK, reactivating namespace"
    UPDATED_STATE=`oci iam tag-namespace reactivate --tag-namespace-id $INACTIVE_TAG_NS_OCID --region $OCI_HOME_REGION | jq -r '.data."lifecycle-state"'`
    echo "Updated state is now $UPDATED_STATE"
    TAG_NS_UNDELETED=true
  fi
fi

TAG_NS_OCID=`oci iam tag-namespace list -c $OCI_TENANCY --include-subcompartments true --all --lifecycle-state ACTIVE  --region $OCI_HOME_REGION | jq -r ".data[] | select (.name == \"$TAG_NS_NAME\") | .id"`
if [ -z "$TAG_NS_OCID" ]
then
  TAG_NS_COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $TAG_NS_COMPARTMENT_OCID | jq -j '.data.name' | sed -e 's/"//g'`
  echo "No active tag namespace called $TAG_NS_NAME found, will attempt to create in compartment $TAG_NS_COMPARTMENT_NAME "
  TAG_NS_OCID=`oci iam tag-namespace create  --compartment-id $TAG_NS_COMPARTMENT_OCID --description "$TAG_NS_NAME namespace" --name $TAG_NS_NAME --region $OCI_HOME_REGION --wait-for-state ACTIVE | jq -r '.data.id'`
  TAG_NS_REUSED=false
else
  TAG_NS_COMPARTMENT_OCID=`oci iam tag-namespace get --tag-namespace-id $TAG_NS_OCID | jq -r '.data."compartment-id"'`
  TAG_NS_COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $TAG_NS_COMPARTMENT_OCID | jq -j '.data.name' | sed -e 's/"//g'`
  echo "Located existing tag namespace $TAG_NS_NAME in compartment $TAG_NS_COMPARTMENT_NAME will reuse"
  if [ "$TAG_NS_UNDELETED" = "true" ]
  then
    TAG_NS_REUSED=false
  else
    TAG_NS_REUSED=true
  fi
fi

echo "$TAG_NS_OCID_NAME=$TAG_NS_OCID" >> $SETTINGS
echo "$TAG_NS_REUSED_NAME=$TAG_NS_REUSED" >> $SETTINGS
echo "$TAG_NS_UNDELETED_NAME=$TAG_NS_UNDELETED" >> $SETTINGS
