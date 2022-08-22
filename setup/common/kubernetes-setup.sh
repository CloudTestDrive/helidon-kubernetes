#!/bin/bash -f
SCRIPT_NAME=`basename $0`

echo "$SCRIPT_NAME is a temporary fix until the OU documentation is updated, it "
echo "is switching to the  $HOME/helidon-kubernrtes/setup/common/oke-setup and"
echo "Then running the oke-cluster-setup.sh script"


cd oke-setup
if [ $# -gt 0 ]
then
  bash oke-cluster-setup.sh $1
else
  bash oke-cluster-setup.sh
fi
