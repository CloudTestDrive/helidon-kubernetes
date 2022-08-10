#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $CERT_AUTHORITY_OCID ]
then
  echo "Cannot locate OCID for the CA , unable to proceed with key of CA deletion"
  exit 0
else
  echo "Locating CA OCID" 
fi

if [ -z $CERT_AUTHORITY_REUSED ]
then
  echo "No reuse information for vault , cannot safely proceed to schedule it's deletion"
else
  if [ $CERT_AUTHORITY_REUSED = true ]
  then
    echo "The vault was reused, cannot safely schedule it's deletion, you will have to delete it by hand"
  else
    if [ -z $CERT_AUTHORITY_OCID ]
    then
      echo "Cannot locate OCID for the CA , unable to schedule it's deletion"
    else
      echo "Scheduling deletion of CA, this will normally take effect in a months time"
      echo "should you with to cancel during that time you can do so."
      echo "Note, a CA that is pending deletion will prevent the compartment that contains it from being deleted"
      NEW_CERT_AUTHORITY_STATE=`oci certs-mgmt certificate-authority schedule-deletion --certificate-authority-id  $CERT_AUTHORITY_OCID | jq -j '.data."lifecycle-state"'`
      echo "CA lifecycle state is $NEW_CERT_AUTHORITY_STATE" 
      echo "Removing details from the settings file"
      bash ./delete-from-saved-settings.sh CERT_AUTHORITY_OCID
      bash ./delete-from-saved-settings.sh CERT_AUTHORITY_REUSED
    fi
  fi
fi

DG_NAME="$USER_INITIALS"CertAuthorityDynamicGroup
POLICY_NAME="$USER_INITIALS"CertAuthorityPolicy
SAVED_DIR=`pwd`
cd ../policies
echo "Deleting policy policy $POLICY_NAME which allows to allowed dynamic group $DG_NAME to manage things in compartment $COMPARTMENT_NAME"
bash ./policy-destroy.sh "$POLICY_NAME"
cd $SAVED_DIR

echo "Deleting dynamic group for the certificate authority"
cd ../dynamic-groups

bash ./dynamic-group-destroy.sh "$DG_NAME" 


cd $SAVED_DIR