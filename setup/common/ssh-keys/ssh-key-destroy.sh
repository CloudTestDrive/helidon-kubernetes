#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 2 ]
then
  echo "$SCRIPT_NAME requires two arguments"
  echo "The directory to contain the ssh keys"
  echo "The \"base\" of the key to use e.g. id_rsa"
  exit 1
fi
export SETTINGS=$HOME/hk8sLabsSettings
if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

SSH_DIR=$1

SSH_KEY_FILE_BASE=$2

SSH_KEY_REUSED_NAME=`bash ../settings/to-valid-name.sh "$SSH_DIR/$SSH_KEY_FILE_BASE"_REUSED`


if [ -z "${!SSH_KEY_REUSED_NAME}" ]
then
  echo "No reuse information, perhaps it's already been removed ? unsafe to proceed"
  exit 0
else
  echo "The SSH key info has been set by this script, continuing"
fi

if [ "${!SSH_KEY_REUSED_NAME}" = true ]
then
  echo "The SSH key pair $SSH_KEY_FILE_BASE in $SSH_DIR was not created by this script not deleting them"
  exit 0
fi

echo "Deleting the SSH key pair $SSH_KEY_FILE_BASE in $SSH_DIR and the pem file"

if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE" ]
then
  echo "Deleted the private key"
  rm  -f "$SSH_DIR/$SSH_KEY_FILE_BASE"
else 
  echo "Private key file could not be located"
fi

if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub ]
then
  echo "Deleted the public key"
  rm  "$SSH_DIR/$SSH_KEY_FILE_BASE".pub
else 
  echo "Public key file could not be located"
fi

if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem ]
then
  echo "Deleted the PEM format public key"
  rm  "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem
else 
  echo "Public key file in PEM format could not be located"
fi

OTHER_ENTRIES=`ls -1 $SSH_DIR | grep -v $SSH_KEY_FILE_BASE | wc -l`

if [ "$OTHER_ENTRIES" = 0 ]
then
  echo "$SSH_DIR is now empty, removing it"
  rmdir $SSH_DIR
fi

bash ../delete-from-saved-settings.sh $SSH_KEY_REUSED_NAME
