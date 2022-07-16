#!/bin/bash -f
if [ $# -eq 0 ]
  then
    echo "No arguments supplied, you must provide the location of your wallet file e.t. $HOME/Wallet.zip"
    exit -1 
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

if [ -z "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" ]
then
  export KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES=0
fi

if [ "$KUBERNETES_CLUSTERS_WITH_INSTALLED_SERVICES" = 0 ]
then
  echo "No other clusters with shared services currently installed, will setup the database wallet"
else
  echo "There are other clusters with the shared services remaining, no need to setup the database wallet"
  exit 0
fi

if [ $# -eq 1 ]
  then
    echo Setting up using $1 as the database wallet download location.
    read -p "Proceed (y/n) ?"
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping db wallet install confirmation"
fi
walletDir=$HOME/helidon-kubernetes/configurations/stockmanagerconf/Wallet_ATP
echo Initiing wallet Directory
mkdir -p $walletDir
cd $walletDir
touch wal
rm *
echo Installing DB wallet in $1 into config
cp $1 $walletDir
unzip $1
