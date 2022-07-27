#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi
# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

# remove the DB and other configuration from the repo

cd $KUBERNETES_LABS_DIR
bash ./unconfigure-downloaded-git-repo.sh $USER_INITIALS


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