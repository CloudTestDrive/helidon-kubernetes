#!/bin/bash -f

SAVED_DIR=`pwd`
cd ../tags
bash ./tag-namespace-setup.sh k3s
bash ./tag-key-setup.sh k3s role "Tags for the k3s cluster management" agent server
cd $SAVED_DIR