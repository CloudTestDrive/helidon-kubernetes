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

SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup
bash ./oke-cluster-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "oke-cluster-destroy returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_PRE_OKE

bash ./database-destroy.sh
RESP=$?
if [ $RESP -ne 0 ]
then
  echo "Failure destroying the database cannot continue"
  exit $RESP
fi

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