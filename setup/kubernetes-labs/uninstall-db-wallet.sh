#!/bin/bash -f

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
  echo "No other clusters with shared services currently installed, will reset the database wallet"
else
  echo "There are other clusters with the shared services remaining, no need to reset the database wallet"
  exit 0
fi

if [ $# -eq 0 ]
  then
    echo "Uninstalling wallet"
    read -p "Proceed (y/n) ?"
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping db wallet uninstall confirmation"
fi
walletDir=$HOME/helidon-kubernetes/configurations/stockmanagerconf/Wallet_ATP
echo Removing wallet Directory
if [ -d $walletDir ]
then
  rm -rf $walletDir
fi