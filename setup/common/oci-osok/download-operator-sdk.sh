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
    echo "No operator settings file( $OPERATOR_SETTINGS_FILE) cannot continue"
    exit 11
fi

if [ -z "$AUTO_CONFIRM" ]
then
  AUTO_CONFIRM=n
fi

if [ -z "$OPERATOR_SDK_REUSED" ]
then
  echo "operator-sdk command not installed by this script, proceeding"
else
  echo "operator-sdk command already installed by this script, exiting"
  exit 0
fi

# makes sure that the directory exists no matter what
mkdir -p $OPERATOR_SDK_DIR

# test for an existing operator-sdk command, if it's there then assume all is OK
if [[ -x $OPERATOR_SDK_PATH ]]
then
  echo "$OPERATOR_SDK_CMD already exists and is executable in $OPERATOR_SDK_DIR, this script is assuming this is the real operator-sdk command and is the latest version, reusing"
  echo "OPERATOR_SDK_REUSED=true" >> $SETTINGS
  exit 0
else
  if [ -f "$OPERATOR_SDK_PATH" ]
  then
    echo "$OPERATOR_SDK_CMD exists in $OPERATOR_SDK_DIR but is not executable, will remove and then re-download"
    rm -rf $OPERATOR_SDK_PATH
  else
    echo "$OPERATOR_SDK_CMD does not exist in $OPERATOR_SDK_DIR will download"
  fi
fi


if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Do you want to download $OPERATOR_SDK_CMD to $OPERATOR_SDK_DIR defaulting to $REPLY"
else
  read -p "Do you want to download $OPERATOR_SDK_CMD to $OPERATOR_SDK_DIR (y/n) " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, not downloading"
  exit 0
fi


mkdir -p $OPERATOR_SDK_DIR

SAVED_DIR=`pwd`
cd $OPERATOR_SDK_DIR

export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.22.2
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
chmod +x operator-sdk_${OS}_${ARCH} && mv operator-sdk_${OS}_${ARCH} $HOME/operator/operator-sdk

cd $SAVED_DIR

# flag it for destruction if needed
echo "OPERATOR_SDK_REUSED=false" >> $SETTINGS 
