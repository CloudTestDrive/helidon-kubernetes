#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

OPERATOR_SETTINGS_FILE=./operator-settings.sh

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ -f $OPERATOR_SETTINGS_FILE ]
  then
    echo "Loading operator settings"
    source $OPERATOR_SETTINGS_FILE
  else 
    echo "No operator settings file( $OPERATOR_SETTINGS_FILE ) cannot continue"
    exit 11
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

if [ -z "$OPERATOR_SDK_REUSED" ]
then
  echo "no operator reuse information, cannot proceed"
  exit 0
else
  echo "reuse info for operator found, proceeding"
fi

if [ "$OPERATOR_SDK_REUSED" = "true" ]
then
  echo "$OPERATOR_SDK_CMD was not installed by this script, will not remove"
  exit 0
fi

# makes sure that the directory exists no matter what
mkdir -p $OPERATOR_SDK_DIR
# make sure that the command file exists
touch $COPERATOR_SDK_PATH
# do we delete the entire directory or just the file ?
# what else is in there
OTHER_ENTRIES=`ls -1 $OPERATOR_SDK_DIR | grep -v $OPERATOR_SDK_DIR_CMD | grep -v "bundle-" wc -l`

# test for an existing clusterctl command, if it's there then assume all is OK
if [ "$OTHER_ENTRIES" = 0 ]
then
  echo "$OPERATOR_SDK_DIR only contains $OPERATOR_SDK_DIR_CMD and operator $BUNDLES_PREFIX files"
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Do you want to remove the entire directory $OPERATOR_SDK_DIR defaulting to $REPLY"
  else
    read -p "Do you want to remove the entire directory $OPERATOR_SDK_DIR (y/n) " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, not deleting"
  else
    echo "OK, Removing the directory $OPERATOR_SDK_DIR"
    rm -rf "$OPERATOR_SDK_DIR"
  fi
else
  echo "$OPERATOR_SDK_DIR contains additional files, removing $OPERATOR_SDK_CMD and $BUNDLES_PREFIX files"
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Do you want to delete $OPERATOR_SDK_CMD and $BUNDLES_PREFIX files in $OPERATOR_SDK_DIR defaulting to $REPLY"
  else
    read -p "Do you want to delete $OPERATOR_SDK_CMD and $BUNDLES_PREFIX files in $OPERATOR_SDK_DIR (y/n) " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, not deleting"
  else
    for BUNDLE in "$OPERATOR_SDK_DIR/$BUNDLES_PREFIX"*
    do
      echo "Deleting bundle $BUNDLE"
      rm -rf $BUNDLE
    done
    echo "OK, Removing the file $OPERATOR_SDK_CMD and $BUNDLES_PREFIX files in $OPERATOR_SDK_DIR"
    rm "$OPERATOR_SDK_PATH"
  fi
fi

# delete script is in common, we are in common/policies
bash ../../common/delete-from-saved-settings.sh OPERATOR_SDK_REUSED