#!/bin/bash -f

SAVED_DIR=`pwd`
cd ../tags
bash ./tag-key-retire.sh k3s role 
bash ./tag-namespace-retire.sh k3s
cd $SAVED_DIR