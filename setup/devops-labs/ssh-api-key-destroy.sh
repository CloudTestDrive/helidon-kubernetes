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

SSH_DIR_NAME=ssh
SSH_DIR=$HOME/$SSH_DIR_NAME
SSH_KEY_FILE_BASE=id_rsa_devops

if [ -z "$DEVOPS_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for devops not previously configured by these scripts, cannot proceed"
  exit 1
else
  echo "These scripts have previously setup the SSH API Key for devops, removing it"
fi

SAVED_PWD=`pwd`

# remove it from the config file

SSH_CONFIG_DIR=$HOME/.ssh
SSH_CONFIG_FILE=$SSH_CONFIG_DIR/config

echo "You need to edit the $SSH_CONFIG_FILE file and remove the entries between the script start and script end comments"

# remove the api key from the users account

cd ../common/api-keys

bash ./api-key-destroy.sh 


# delete the ssh key files

cd $SAVED_PWD 
cd ../common/ssh-keys

bash ./ssh-key-destroy.sh $SSH_DIR $SSH_KEY_FILE_BASE

cd $SAVED_PWD

bash ../common/delete-from-saved-settings.sh DEVOPS_SSH_API_KEY_CONFIGURED