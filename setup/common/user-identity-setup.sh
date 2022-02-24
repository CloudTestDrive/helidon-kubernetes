#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo Loading existing settings
    source $SETTINGS
  else 
    echo No existing settings, using defaults
fi

if [ -z $USER_OCID ]
  then
    echo "No existing user info, retrieving"
  else
    USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'` 
    echo "User OCID is already set to and maps to $USERNAME"
    echo "To reset this run the user-identity-destroy.sh script"
    exit 1
fi


# work out the users id, usually this will be in the oracleidentitycloudservice, but not always !
# If the OCI_CS_USER_OCID starts with ocid1.user then they are a local user, so can use that directly to get the users info
# If it starts with ocid1.saml then they are a federated user and we'll have to parse the user name out and out oracleidentitycloudservice in front of it
# If it doesn't start with either then the user will need to provide the name themselves.

echo Checking for local user
LOCAL_USER=`echo $OCI_CS_USER_OCID | grep '^ocid1.user' | wc -l`

if [ $LOCAL_USER = 1 ]
  then
    echo USER_OCID=$OCI_CS_USER_OCID >> $SETTINGS
    echo USER_TYPE=local >> $SETTINGS
    USERNAME=`oci iam user get --user-id $OCI_CS_USER_OCID | jq -j '.data.name'`
    echo "You are a local user, and do not use an identity provider, your user name is $USERNAME, saved details"
    exit 0
fi

echo Checking for federated user
FEDERATED_USER=`echo $OCI_CS_USER_OCID | grep '^ocid1.saml' | wc -l`

if [ $FEDERATED_USER = 1 ]
  then
    echo "You are a federated user, getting information"
    PROVIDER_OCID=`cut -d '/' -f 1 <<< $OCI_CS_USER_OCID`
    USER_ID=`cut -d '/' -f 2 <<< $OCI_CS_USER_OCID`
    # look through all of the proders looking for one that matches
    # we only know about SAML2 though
    PROVIDER_NAME=`oci iam identity-provider list --compartment-id $OCI_TENANCY --protocol SAML2 --all | jq -j ".data[] | select (.id == \"$PROVIDER_OCID\") | .name" | tr [:upper:] [:lower:] `
    USERNAME_PROVISIONAL=$PROVIDER_NAME/$USER_ID
    USER_OCID=`oci iam user list --name $USERNAME_PROVISIONAL | jq -j '.data[0].id'`
    if [ -z $USER_OCID ]
    then
      echo "Cannot locate OCID for user named $USERNAME_PROVISIONAL"
      echo "you will have to locate your user OCID"
      echo "in the OCI Console then edit the file $SETTINGS"
      echo "and add lines of the form"
      echo 'export USER_OCID=<user odic>'
      echo 'export USER_TYPE=[local or federated]'
      exit 11
    fi
    echo USER_OCID=$USER_OCID >> $SETTINGS
    echo USER_TYPE=federated >> $SETTINGS
    USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`
    echo "You are a federated user, your user name is $USERNAME, saved details"
    exit 0
fi

echo "Unknown user type $OCI_CS_USER_OCID"
echo "You may be using an Active Directory federated user,"
echo "in which case you will have to locate your user OCID"
echo "in the OCI Console then edit the file $SETTINGS"
echo "and add lines of the form"
echo 'export USER_OCID=<user odic>'
echo 'export USER_TYPE=[local or federated]'