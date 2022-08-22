#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings
if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi
KEY_NAME=capi
SSH_DIR_NAME=ssh
SSH_DIR=$HOME/$SSH_DIR_NAME
SSH_KEY_FILE_BASE=id_rsa_$KEY_NAME

if [ -z "$CAPI_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for $KEY_NAME noreuse info, cannot proceed, exiting"
  exit 0
else
  echo "These scripts have previously setup the SSH API Key for $KEY_NAME, that configuration"
  echo "will be removed."
fi

SAVED_PWD=`pwd`
cd ../api-keys

bash ./api-key-destroy.sh $KEY_NAME
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure uploading the $KEY_NAME api ssh keys, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# Upload it

cd $SAVED_PWD
# delete the ssh key itself
cd ../ssh-keys

bash ./ssh-key-destroy.sh $SSH_DIR $SSH_KEY_FILE_BASE
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the ssh keys, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# remove any existing reuse info on the API key
bash ../delete-from-saved-settings.sh CAPI_SSH_API_KEY_CONFIGURED