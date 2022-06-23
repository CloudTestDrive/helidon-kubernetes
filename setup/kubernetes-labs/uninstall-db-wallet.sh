#!/bin/bash -f
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