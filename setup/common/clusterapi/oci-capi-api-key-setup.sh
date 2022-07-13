#!/bin/bash -f

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
  echo "SSH API Key for $KEY_NAME not previously configured, setting up"
else
  echo "These scripts have previously setup the SSH API Key for $KEY_NAME, that configuration"
  echo "will be reused. To remove it please run the capi-api-key-destroy.sh script"
  exit 0
fi

SAVED_PWD=`pwd`

# create the ssh key
cd ../ssh-keys

bash ./ssh-key-setup.sh $SSH_DIR $SSH_KEY_FILE_BASE
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure creating the ssh keys, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# Upload it

cd $SAVED_PWD

cd ../api-keys

bash ./api-key-setup.sh $KEY_NAME "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure uploading the $KEY_NAME api ssh keys, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# remove any existing info on the API key
bash ../delete-from-saved-settings.sh CAPI_SSH_API_KEY_CONFIGURED
echo CAPI_SSH_API_KEY_CONFIGURED=true >> $SETTINGS