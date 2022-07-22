#!/bin/bash -f

# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

KUBEFLOW_CLUSTER_NAME=kubeflow

SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup
bash ./oke-cluster-destroy.sh $KUBEFLOW_CLUSTER_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "oke-cluster-destroy returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_PRE_OKE

bash ./core-environment-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "core environment destroy returned an error, unable to continue"
  exit $RESP
fi

# until I figure out a way to determine if we've used the last of the keys (they can be manually and 
# script created) leave the step command and root stuff there for now
#if [ -d $HOME/keys ]
#then
#  rm -rf $HOME/keys
#fi

exit 0