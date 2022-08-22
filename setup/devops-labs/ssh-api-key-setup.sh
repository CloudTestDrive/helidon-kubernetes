#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings
if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot contiue"
    exit 10
fi

SSH_DIR_NAME=ssh
SSH_DIR=$HOME/$SSH_DIR_NAME
SSH_KEY_FILE_BASE=id_rsa_devops

if [ -z "$DEVOPS_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for devops not previously configured, setting up"
else
  echo "These scripts have previously setup the SSH API Key for devops, that configuration"
  echo "will be reused. To remove it please run the ssh-api-key-destroy.sh script"
  exit 0
fi

SAVED_PWD=`pwd`

# create the ssh key
cd ../common/ssh-keys

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

cd ../common/api-keys

bash ./api-key-setup.sh devops "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure uploading the api ssh keys, exit code is $RESP, cannot continue"
  echo "Please review the output and rerun the script"
  exit $RESP
fi 

# update the .ssh file

echo "Configuring SSH to use key"
cd $SAVED_PWD

SSH_CONFIG_DIR=$HOME/.ssh
SSH_CONFIG_FILE=$SSH_CONFIG_DIR/config

USER_NAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`
TENANCY_NAME=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data.name'`

mkdir -p $HOME/.ssh
echo "# Start of script added lines" >> $SSH_CONFIG_FILE
echo 'Host devops.scmservice.*.oci.oraclecloud.com' >> $SSH_CONFIG_FILE
echo "  User $USER_NAME@$TENANCY_NAME" >> $SSH_CONFIG_FILE
echo "  IdentityFile $SSH_DIR/$SSH_KEY_FILE_BASE" >> $SSH_CONFIG_FILE
echo "# End of script added lines" >> $SSH_CONFIG_FILE

# remove any existing info on the API key
bash ../common/delete-from-saved-settings.sh DEVOPS_SSH_API_KEY_CONFIGURED
echo DEVOPS_SSH_API_KEY_CONFIGURED=true >> $SETTINGS