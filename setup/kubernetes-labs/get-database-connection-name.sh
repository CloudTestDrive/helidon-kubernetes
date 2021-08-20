#!/bin/bash
walletDir=$HOME/helidon-kubernetes/configurations/stockmanagerconf/Wallet_ATP
tns=$walletDir/tnsnames.ora
grep _high $tns | awk '{print $1}'