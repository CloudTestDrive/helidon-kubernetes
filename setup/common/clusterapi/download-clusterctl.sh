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
    echo "No capi settings file( $CAPI_SETTINGS_FILE) cannot continue"
    exit 11
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

if [ -z "$CLUSTERCTL_REUSED" ]
then
  echo "clusterctl command not installed by this script, proceeding"
else
  echo "clusterctl command already installed by this script, exiting"
  exit 0
fi

# makes sure that the directory exists no matter what
mkdir -p $CLUSTERCTL_DIR

# test for an existing clusterctl command, if it's there then assume all is OK
if [[ -x $CLUSTERCTL_PATH ]]
then
  echo "$CLUSTERCTL_CMD already exists and is executable in $CLUSTERCTL_DIR, this script is assuming this is the real clusterctl command and is the latest version, reusing"
  echo "CLUSTERCTL_REUSED=true" >> $SETTINGS
  exit 0
else
  if [ -f "$CLUSTERCTL_PATH" ]
  then
    echo "$CLUSTERCTL_CMD exists in $CLUSTERCTL_DIR but is not executable, will remove and then re-download"
    rm -rf $CLUSTERCTL_PATH
  else
    echo "$CLUSTERCTL_CMD does not exist in $CLUSTERCTL_DIR will download"
  fi
fi


if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, using $CLUSTER_NAME_FULL question for cluster name defaulting to $REPLY"
else
  read -p "Do you want to download $CLUSTERCTL_CMD to $CLUSTERCTL_PATH (y/n) " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not downloading"
  exit 0
else
  echo "Downloading clusterctl version $CLUSTERCTL_CMD to $CLUSTERCTL_DIR"
  curl -s -S -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v$CLUSTERCTL_VERSION/clusterctl-linux-amd64 -o $CLUSTERCTL_PATH
  echo "Making $CLUSTERCTL_CMD executable"
  chmod +x $CLUSTERCTL_PATH

  # flag it for destruction if needed
  echo "CLUSTERCTL_REUSED=false" >> $SETTINGS 
fi