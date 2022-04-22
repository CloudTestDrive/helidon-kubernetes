#!/bin/bash -f

# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

cd $COMMON_DIR

bash ./image-environment-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "image environment destroy returned an error, unable to continue"
  exit $RESP
fi

bash ./kubernetes-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "kubernetes cluster destroy returned an error, unable to continue"
  exit $RESP
fi

bash ./core-environment-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "core environment destroy returned an error, unable to continue"
  exit $RESP
fi

if [ -d $HOME/keys ]
then
  rm -rf $HOME/keys
fi

exit 0