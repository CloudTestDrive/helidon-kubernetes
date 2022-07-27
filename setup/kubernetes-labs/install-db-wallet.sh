#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "   1st arg the location of your wallet file e.g. $HOME/Wallet.zip"
    exit -1 
fi
WALLET_LOCATION=$1
if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Setting up using $WALLET_LOCATION as the database wallet download location defaults to $REPLY"
else
  echo "Setting up using $WALLET_LOCATION as the database wallet download location."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
 echo "Setting up using $WALLET_LOCATION as the database wallet download location."
fi
walletDir=$HOME/helidon-kubernetes/configurations/stockmanagerconf/Wallet_ATP
echo "Initiing wallet Directory"
mkdir -p $walletDir
cd $walletDir
touch wal
rm *
echo "Installing DB wallet in $WALLET_LOCATION into config"
cp $WALLET_LOCATION $walletDir
unzip $WALLET_LOCATION
