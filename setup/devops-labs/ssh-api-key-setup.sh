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
SSH_KEY_FILE_BASE=id_rsa

if [ -z "$DEVOPS_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for devops not previously configured, setting up"
else
  echo "These scripts have previously setup the SSH API Key for devops, to remove it please run the ssh-api-key-destroy.sh script"
  exit 1
fi

SAVED_PWD=`pwd`

# create the ssh key
cd ../common/ssh-keys

bash ./ssh-key-setup.sh $SSH_DIR $SSH_KEY_FILE_BASE

# Upload it

cd $SAVED_PWD

cd ../common/api-keys

bash ./api-key-setup.sh "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem

# update the .ssh file
cd $SAVED_PWD

SSH_CONFIG_DIR=$HOME/.ssh
SSH_CONFIG_FILE=$SSH_CONFIG_DIR/config

USER_NAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`
TENANCY_NAME=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data.name'`

mkdir -p $HOME/.ssh
echo 'Host devops.scmservice.*.oci.oraclecloud.com # SCRIPT ADDED' >> $SSH_CONFIG_FILE
echo "  User $USER_NAME@$TENANCY_NAME # SCRIPT ADDED" >> $SSH_CONFIG_FILE
echo "  IdentityFile ~/$SSH_DIR/$SSH_KEY_FILE_BASE # SCRIPT ADDED" >> $SSH_CONFIG_FILE

echo DEVOPS_SSH_API_KEY_CONFIGURED=true >> $SETTINGS