#!/bin/bash -f
SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
export CA_SETTINGS=cert-authority-settings.sh

if [ -f $CA_SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing CA settings information"
    source $CA_SETTINGS
  else 
    echo "$SCRIPT_NAME No existing CA settings cannot continue"
    exit 11
fi
if [ -z $USER_INITIALS ]
then
  echo "Your initials have not been set, you need to run the initials-setup.sh script before you can run thie script"
  exit 1
fi


if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z "$CERT_AUTHORITY_REUSED" ]
then
  echo "No certificate authority reuse information found, continuing"
else
  echo "the certificate authority has already been setup using these scripts, existing"
  exit 0
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
SAVED_DIR=`pwd`
cd ../vault
VAULT_KEY_NAME=`bash ./vault-key-get-key-name.sh $CERT_VAULT_KEY_NAME`
VAULT_KEY_OCID_NAME=`bash ./vault-key-get-var-name-ocid.sh $VAULT_KEY_NAME`
VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"
cd $SAVED_DIR
if [ -z $VAULT_KEY_OCID ]
then
  echo "Can't find the OCID for your vault key $CERT_VAULT_KEY_NAME  variable $VAULT_KEY_OCID_NAME has not been set, you need to run the cert-authority-vault-key-setup.sh before you can run this script"
  exit 2
fi


# Get the comparment name
COMPARTMENT_NAME=`oci iam compartment get --compartment-id $COMPARTMENT_OCID | jq -r '.data.name'`

echo "Creating dynamic group for the certificate authority"
SAVED_DIR=`pwd`
cd ../dynamic-groups
DG_NAME="$USER_INITIALS"CertAuthorityDynamicGroup

bash ./dynamic-group-by-resource-type-setup.sh "$DG_NAME" certificateauthority "Identifies the certificate authority"

cd $SAVED_DIR
cd ../policies
echo "Creating policy to allow dynamic group $DG_NAME so manage things in compartment $COMPARTMENT_NAME"
POLICY_NAME="$USER_INITIALS"CertAuthorityPolicy
POLICY_RULE="[\"Allow dynamic-group $DG_NAME to use keys in compartment $COMPARTMENT_NAME\", \"Allow dynamic-group $DG_NAME to manage objects in compartment $COMPARTMENT_NAME\"]"
POLICY_DESCRIPTION="Allows the cert Dg to manage things"
bash ./policy-by-text-setup.sh "$POLICY_NAME" "$POLICY_RULE" "$POLICY_DESCRIPTION"
cd $SAVED_DIR

CA_NAME="$USER_INITIALS"LabCertAuthority
echo "Checking for pending delete CA"
echo "Checking for CA $CA_NAME in compartment $COMPARTMENT_NAME"
CA_SCHEDULING_DELETION_OCID=`oci certs-mgmt certificate-authority list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data.items[] | select ((.\"lifecycle-state\"==\"SCHEDULING_DELETION\") and (.\"display-name\"==\"$CA_NAME\"))] | first | .id" `
if [ -z "$SCHEDULING_DELETION_OCID" ]
then
  CA_SCHEDULING_DELETION_OCID=null
fi
if [ "$CA_SCHEDULING_DELETION_OCID" = "null" ]
then
  echo "No CA's named $CA_NAME in scheduling deletion state, continuing"
else
  echo "There is a CA named $CA_NAME that currently has a scheduling deletion activity"
  echo "underway, please wait until that has finished (this may take a few mins) then re-run"
  echo "this script to cancel the deletion and re-use that CA"
  exit 2
fi

# initially defauslt to the CA is not undeleted
CA_UNDELETED=false
CA_KEY_UNDELETED=false
if [ -z "$CERT_AUTHORITY_REUSED" ]
then
  echo "No reuse information for CA"

  CA_NAME="$USER_INITIALS"LabsCA
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled,  use $CA_NAME as the name of the CA to create or re-use in $COMPARTMENT_NAME defaulting to $REPLY"
  else
    read -p "Do you want to use $CA_NAME as the name of the CA to create or re-use in $COMPARTMENT_NAME (y/n) ?" REPLY
  fi
  
  if [[ ! "$REPLY" =~ ^[Yy]$ ]]
  then
    echo "OK, please enter the name of the CA to create / re-use, it must be a single word, e.g. tgLabsCA"
    read CA_NAME
    if [ -z "$CA_NAME" ]
    then
      echo "You do actually need to enter the new name for the CA, exiting"
      exit 1
    fi
  else     
    echo "OK, going to use $CA_NAME as the CA name"
  fi

  #allow for re-using an existing CA if specified  
  if [ -z "$CERT_AUTHORITY_OCID" ]
    then
    # No existing CERT_AUTHORITY_OCID so need to potentially create it
    echo "Checking for  CA $CA_NAME in compartment $COMPARTMENT_NAME"
    SCHEDULING_DELETION_CERT_AUTHORITY_OCID=`oci certs-mgmt certificate-authority list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data.items[] | select ((.\"lifecycle-state\"==\"SCHEDULING_DELETION\") and (.\"display-name\"==\"$CA_NAME\"))] | first | .id" `
    if [ -z "$SCHEDULING_DELETION_CERT_AUTHORITY_OCID" ]
    then
      SCHEDULING_DELETION_CERT_AUTHORITY_OCID=null
    fi
    if [ "$SCHEDULING_DELETION_CERT_AUTHORITY_OCID" = "null" ]
    then
      echo "No CAs named $CA_NAME in scheduling deletion state, continuing"
    else
      echo "There is a CA named $CA_NAME that currently has a scheduling deletion activity"
      echo "underway, please wait until that has finished (this may take a few mins) then re-run"
      echo "this script to cancel the deletion and re-use that CA"
      exit 2
    fi
    CERT_AUTHORITY_PENDING_OCID=`oci certs-mgmt certificate-authority list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data.items[] | select ((.\"lifecycle-state\"==\"PENDING_DELETION\") and (.\"display-name\"==\"$CA_NAME\"))] | first | .id" `
    if [ -z "$CERT_AUTHORITY_PENDING_OCID" ]
    then
      CERT_AUTHORITY_PENDING_OCID=null
    fi
    if [ "$CERT_AUTHORITY_PENDING_OCID" = "null" ]
    then
      echo "No CA named $CA_NAME pending deletion, continuing"
    else
      if [ "$AUTO_CONFIRM" = true ]
      then
        REPLY="y"
        echo "Auto confirm is enabled,  found an existing fault named $CA_NAME but it is pending deletion, cancel the deletion and re-use it defaulting to $REPLY"
      else
        read -p "Found an existing fault named $CA_NAME but it is pending deletion, cancel the deletion and re-use it (y/n) ?" REPLY
      fi
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo "OK will try to create a new CA for you with this name $CA_NAME"
      else
        echo "OK, trying to cancel CA deletion"
        oci certs-mgmt certificate-authority cancel-deletion --certificate-authority-id $CERT_AUTHORITY_PENDING_OCID --wait-for-state ACTIVE
        CA_UNDELETED=true
      fi
    fi
    CERT_AUTHORITY_OCID=`oci certs-mgmt certificate-authority list --compartment-id $COMPARTMENT_OCID --all | jq -j "[.data.items[] | select ((.\"lifecycle-state\"==\"ACTIVE\") and (.\"display-name\"==\"$CA_NAME\"))] | first | .id" `
    if [ -z "$CERT_AUTHORITY_OCID" ]
    then
      CERT_AUTHORITY_OCID=null
    fi
    if [ "$CERT_AUTHORITY_OCID" = "null" ]
    then
      echo "CA named $CA_NAME doesn't exist, creating it, there may be a short delay"
      echo "Creating certificate authority"
      CERT_AUTHORITY_OCID=`oci certs-mgmt certificate-authority create-root-ca-by-generating-config-details --compartment-id $COMPARTMENT_OCID --name $CA_NAME --subject "{\"commonName\" : \"LabsCA\"}" --kms-key-id $VAULT_KEY_OCID | jq -j '.data.id'`
      RESP=$?
      if [ "$RESP" -ne 0 ]
      then
        echo "Unexpected non zero response ( $RESP) creating cert authority, unable to continue"
        exit $RESP
      fi
      echo "CA being created using OCID $CERT_AUTHORITY_OCID"
      echo "CERT_AUTHORITY_OCID=$CERT_AUTHORITY_OCID" >>$SETTINGS
      echo "CERT_AUTHORITY_REUSED=false" >> $SETTINGS
    else
      echo "Found existing CA names $CA_NAME, reusing it"
      echo "CERT_AUTHORITY_OCID=$CERT_AUTHORITY_OCID" >> $SETTINGS
      # if we undeleted the CA then the delete script can undelete it as well
      if [ "$CA_UNDELETED" = "true" ]
      then
        echo "CERT_AUTHORITY_REUSED=false" >> $SETTINGS
      else
        echo "CERT_AUTHORITY_REUSED=true" >> $SETTINGS
      fi
    fi
  else
    # We've been given an CERT_AUTHORITY_OCID, let's check if it's there, if so assume it's been configured already
    echo "Trying to locate CA using specified OCID $CERT_AUTHORITY_OCID"
    CA_NAME=`oci certs-mgmt certificate-authority get --certificate-authority-id $CERT_AUTHORITY_OCID | jq -j '.data."display-name"'`
    if [ -z "$CA_NAME" ]
    then
      CA_NAME=null
    fi
    if [ "$CA_NAME" = "null" ]
    then
      echo "Unable to locate CA for OCID $CERT_AUTHORITY_OCID"
      echo "Please check that the value of CERT_AUTHORITY_OCID in $SETTINGS is correct if nor remove or replace it"
      exit 5
    else
      echo "Located CA named $CA_NAME with pre-specified OCID of $CERT_AUTHORITY_OCID, checking status"
      CA_LIFECYCLE=`oci certs-mgmt certificate-authority get --certificate-authority-id $CERT_AUTHORITY_OCID | jq -j '.data."lifecycle-state"'`
      if [ "$CA_LIFECYCLE" -ne "ACTIVE" ]
      then
        echo "CA $CA_NAME is not active, cannot use it"
      else
        echo "CA $CA_NAME is active, reusing it"
        echo "CERT_AUTHORITY_REUSED=true" >> $SETTINGS
      fi
    fi
  fi
else
  echo "This script has already configured CA details"
  if [ -z "$CERT_AUTHORITY_OCID" ]
  then
    echo "No CERT_AUTHORITY_OCID available in the state file ( $SETTINGS )"
    echo "Edit the state file and provide the CERT_AUTHORITY_OCID or remove CERT_AUTHORITY_REUSED"
    echo 12
  fi
  CA_NAME=`oci certs-mgmt certificate-authority get --certificate-authority-id $CERT_AUTHORITY_OCID | jq -j '.data."display-name"'`
  if [ -z "$CA_NAME" ]
  then
    CA_NAME=null
  fi
  if [ "$CA_NAME" = "null" ]
  then
    echo "Unable to retrieve details of CA with OCID $CERT_AUTHORITY_OCID, please check that it hasn't been deleted"
    exit 13
  else
    echo "CA with OCID $CERT_AUTHORITY_OCID is named $CA_NAME"
  fi
fi