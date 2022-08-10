#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -ne 3 ]
then
  echo "$SCRIPT_NAME requires four arguments:"
  echo "1st The name of the key to protect this secret E.g. AES"
  echo "2nd is the name of the setting e.g. OCIR_HOST - the script will appaned / prepend the required strings around that value"
  echo "3rd the description to be used - note that is this is multiple words it must be in quotes"
  echo "4th the value to be used for the secret"
fi
VAULT_KEY_NAME=$1
SETTINGS_NAME=$2
VAULT_SECRET_DESCRIPTION=$3
VAULT_SECRET_VALUE=$4

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 11
fi

if [ -z $VAULT_OCID ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  echo "Cannot continue"
  exit 12
else
  echo "Found vault information"
fi

# Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
VAULT_KEY_OCID_NAME=`bash ../settings/to-valid-name.sh  "VAULT_KEY_"$VAULT_KEY_NAME"_OCID`
# Now locate the value of the variable who's name is in VAULT_KEY_OCID_NAME and save it
VAULT_KEY_OCID="${!VAULT_KEY_OCID_NAME}"
if [ -z $VAULT_KEY_OCID ]
then
  echo "No vault key OCID set, have you run the vault-key-setup.sh script for key $VAULT_KEY_NAME?"
  echo "Cannot continue"
  exit 13
else
  echo "Found OCID for vault key $VAULT_KEY_NAME"
fi

VAULT_SECRET_NAME=$SETTINGS_NAME"_VAULT"
SECRET_REUSED_VAR_NAME="VAULT_SECRET_"$SETTINGS_NAME"_REUSED"

if [ -z "${!SECRET_REUSED_VAR_NAME}" ] 
then
  echo "No existing reuse information for "$SETTINGS_NAME"_VAULT, continuing"
else
  echo "The "$SETTINGS_NAME"_VAULT secret has already been setup, will not be recreated."
  VAULT_SECRET_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state ACTIVE --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`
  VAULT_SECRET_CONTENTS=`oci secrets secret-bundle get --secret-id $VAULT_SECRET_OCID --stage CURRENT | jq -r '.data."secret-bundle-content".content' | base64 --decode`
  if [ "$VAULT_SECRET_CONTENTS" = "$VAULT_SECRET_VALUE" ]
  then
    echo "The vault secret contains the contents you specified of $VAULT_SECRET_VALUE"
    echo "The OCID for the $VAULT_SECRET_NAME secret is $VAULT_SECRET_OCIR_HOST_OCID "
    exit 0
  else
    echo "The vault secret contents of $VAULT_SECRET_CONTENTS does not match the content you specified of $VAULT_SECRET_VALUE"
    exit 2
  fi
fi

BASE64_VAULT_SECRET_VALUE=`echo $VAULT_SECRET_VALUE | base64`
#lets see it it exists already
echo "Checking if secret $VAULT_SECRET_NAME already exists"
VAULT_SECRET_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state ACTIVE --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`

VAULT_SECRET_PENDING_DELETION_OCID=`oci vault secret list --compartment-id $COMPARTMENT_OCID --all --lifecycle-state PENDING_DELETION --name $VAULT_SECRET_NAME --vault-id $VAULT_OCID | jq -j '.data[0].id'`
if [ -z $VAULT_SECRET_PENDING_DELETION_OCID ]
then
  if [ -z $VAULT_SECRET_OCID ]
  then
    echo "secret $VAULT_SECRET_NAME Does not exist, creating it and setting it to $VAULT_SECRET_VALUE and description $VAULT_SECRET_DESCRIPTION"
    # Create the secrets
    VAULT_SECRET_OCID=`oci vault secret create-base64 --compartment-id $COMPARTMENT_OCID --secret-name $VAULT_SECRET_NAME --vault-id "$VAULT_OCID" --description "$VAULT_SECRET_DESCRIPTION" --key-id "$VAULT_KEY_OCID"  --secret-content-content "$BASE64_VAULT_SECRET_VALUE" | jq -j '.data.id'`
    RESP=$?
    if [ $RESP -ne 0 ]
    then
      echo "Failure creating the vault secret $VAULT_SECRET_NAME, exit code is $RESP, cannot continue"
      echo "Please review the output and rerun the script"
      exit $RESP
    fi  
    echo "VAULT_SECRET_"$SETTINGS_NAME"_OCID=$VAULT_SECRET_OCID" >> $SETTINGS
    echo "VAULT_SECRET_"$SETTINGS_NAME"_REUSED=false" >> $SETTINGS
  else
    # it exists, we will just re-use it
    echo "$VAULT_SECRET_NAME already exists, reusing it"
    VAULT_SECRET_CONTENTS=`oci secrets secret-bundle get --secret-id $VAULT_SECRET_OCID --stage CURRENT | jq -r '.data."secret-bundle-content".content' | base64 --decode`
    if [ $VAULT_SECRET_VALUE = $VAULT_SECRET_CONTENTS ]
    then
      echo "The contents of the existing secret match the provided value of $VAULT_SECRET_VALUE"
    else
      echo "The contents of the existing secret are $VAULT_SECRET_CONTENTS this does not match the"
      echo "specified value of $VAULT_SECRET_VALUE"
      echo "This script will not overwrite the existing contents as it may be needed for other"
      echo "purposes, however yor lab will probabaly not work until you manually create a new secret version"
      echo "with the specified contents of $VAULT_SECRET_VALUE" 
    fi
    echo "VAULT_SECRET_"$SETTINGS_NAME"_OCID=$VAULT_SECRET_OCID" >> $SETTINGS
    echo "VAULT_SECRET_"$SETTINGS_NAME"_REUSED=true" >> $SETTINGS
  fi
  echo "The OCID for the $VAULT_SECRET_NAME secret is $VAULT_SECRET_OCID"
else
  echo "A Vault secret named $VAULT_SECRET_NAME already exists but has a deletion scheduled. It "
  echo "cannot be used unless the deletion is cancled."
  read -p "Do you want to cancel the pending deletion (y/n) ? " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you cannot use the secret name $VAULT_SECRET_NAME, you can manually create another secret"
    echo "to hold this information with value $VAULT_SECRET_VALUE and use it's OCID in the labs"
    exit 1
  else
    echo "OK, canceling pending deletion"
    oci vault secret cancel-secret-deletion --secret-id  $VAULT_SECRET_PENDING_DELETION_OCID
    RESP=$?
    if [ $RESP -ne 0 ]
    then
      echo "Failure canceling pending vault deletion the vault secret $VAULT_SECRET_NAME, exit code is $RESP, cannot continue"
      echo "Please review the output and rerun the script"
      exit $RESP
    fi 
    VAULT_SECRET_STATE=`oci vault secret get --secret-id  $VAULT_SECRET_PENDING_DELETION_OCID | jq -r '.data."lifecycle-state"'`
    while [ $VAULT_SECRET_STATE !=  ACTIVE ]
    do
      echo "Waiting for deletion cancelation to complete, state is $VAULT_SECRET_STATE"
      sleep 5
      VAULT_SECRET_STATE=`oci vault secret get --secret-id  $VAULT_SECRET_PENDING_DELETION_OCID | jq -r '.data."lifecycle-state"'`
    done
    echo "Pending deletion cancled, validating secret contents"
    VAULT_SECRET_CONTENTS=`oci secrets secret-bundle get --secret-id $VAULT_SECRET_PENDING_DELETION_OCID --stage CURRENT | jq -r '.data."secret-bundle-content".content' | base64 --decode`
    if [ $VAULT_SECRET_VALUE = $VAULT_SECRET_CONTENTS ]
    then
      echo "The contents of the undeleted secret match the provided value of $VAULT_SECRET_VALUE"
    else
      echo "The contents of the undeleted secret are $VAULT_SECRET_CONTENTS this does not match the"
      echo "specified value of $VAULT_SECRET_VALUE"
      echo "This script will not overwrite the existing contents as it may be needed for other"
      echo "purposes, however yor lab will probabaly not work until you manually create a new secret version"
      echo "with the specified contents of $VAULT_SECRET_VALUE" 
      exit 2
    fi
    echo "Saving details of restored secet"
    echo "VAULT_SECRET_"$SETTINGS_NAME"_OCID=$VAULT_SECRET_PENDING_DELETION_OCID" >> $SETTINGS
    echo "VAULT_SECRET_"$SETTINGS_NAME"_REUSED=false" >> $SETTINGS
  fi
fi
