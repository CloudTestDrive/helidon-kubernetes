#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

CAPI_SETTINGS_FILE=./capi-settings.sh

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ -f $CAPI_SETTINGS_FILE ]
  then
    echo "Loading capi settings"
    source $CAPI_SETTINGS_FILE
  else 
    echo "No capi settings file( $CAPI_SETTINGS_FILE ) cannot continue"
    exit 11
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

if [ -z "$CLUSTERCTL_REUSED" ]
then
  echo "no clusterctl reuse information, cannot proceed"
  exit 0
else
  echo "reuse info for clusterctl found, proceeding"
fi

if [ "$CLUSTERCTL_REUSED" = "true" ]
then
  echo "$CLUSTERCTL_CMD was not installed by this script, will not remove"
  exit 0
fi

# makes sure that the directory exists no matter what
mkdir -p $CLUSTERCTL_DIR
# make sure that the command file exists
touch $CLUSTERCTL_PATH
# do we delete the entire directory or just the file ?
# what else is in there
OTHER_ENTRIES=`ls -1 $CLUSTERCTL_DIR | grep -v $CLUSTERCTL_CMD | wc -l`

# test for an existing clusterctl command, if it's there then assume all is OK
if [ "$OTHER_ENTRIES" = 0 ]
then
  echo "$CLUSTERCTL_DIR only contains $CLUSTERCTL_CMD"
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Do you want to remove the entire directory $CLUSTERCTL_PATH defaulting to $REPLY"
  else
    read -p "Do you want to remove the entire directory $CLUSTERCTL_PATH (y/n) " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, not deleting"
  else
    echo "OK, Removing the directory $CLUSTERCTL_DIR"
    rm -rf $CLUSTERCTL_DIR
  fi
else
  echo "$CLUSTERCTL_DIR contains additional files, only removing $CLUSTERCTL_CMD"
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, Do you want to delete $CLUSTERCTL_CMD in $CLUSTERCTL_PATH defaulting to $REPLY"
  else
    read -p "Do you want to delete $CLUSTERCTL_CMD in $CLUSTERCTL_PATH (y/n) " REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, not deleting"
  else
    echo "OK, Removing the file $CLUSTERCTL_CMD in $CLUSTERCTL_PATH"
    rm $CLUSTERCTL_CMD
  fi
fi

# delete script is in common, we are in common/policies
bash ../../common/delete-from-saved-settings.sh CLUSTERCTL_REUSED