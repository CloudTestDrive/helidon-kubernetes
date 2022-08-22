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
  echo "No saved SSH key information, continuing."
else
  echo "Your SSH key has already been set using these scripts, it will be reused"
  exit 0
fi

if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem ]
then
  echo "PEM format file already exists, no idea if this is connected to the key pair, buf for saftey will not overwrite it or proceed"
  exit 3
fi
if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE" ]
then
  if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub ]
  then
    SSH_KEY_FILE_REUSED=true
    echo "Found both parts of the $SSH_KEY_FILE_BASE key pair in $SSH_DIR will reuse"
  else
    echo "Located the private key $SSH_KEY_FILE_BASE in $SSH_DIR but can't find the public key $SSH_DIR/$SSH_KEY_FILE_BASE.pub cannot continue as no public key to upload"
    exit 4
  fi
else
  if [ -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub ]
  then
    echo "Located the the public key $SSH_DIR/$SSH_KEY_FILE_BASE.pub but can't find the private key $SSH_KEY_FILE_BASE in $SSH_DIR cannot continue as no connections could be established"
    exit 4
  else
    SSH_KEY_FILE_REUSED=false
    echo "Did not find any parts of the $SSH_KEY_FILE_BASE key pair in $SSH_DIR will create and upload"
  fi
fi

if [ "$SSH_KEY_FILE_REUSED" = false ]
then
  echo "Generating ssh kep pair"
  mkdir -p $SSH_DIR
  ssh-keygen -t rsa -f "$SSH_DIR/$SSH_KEY_FILE_BASE" -N ""
  chmod 400 "$SSH_DIR/$SSH_KEY_FILE_BASE"
fi

echo "Generating PEM file from public key file"
ssh-keygen -f "$SSH_DIR/$SSH_KEY_FILE_BASE".pub -e -m pkcs8 > "$SSH_DIR/$SSH_KEY_FILE_BASE".pub.pem

echo "$SSH_KEY_REUSED_NAME=$SSH_KEY_FILE_REUSED" >> $SETTINGS
