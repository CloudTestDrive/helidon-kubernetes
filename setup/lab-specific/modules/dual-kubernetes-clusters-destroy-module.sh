#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings, cannot continue"
  exit 10
fi
CLUSTER_CONTEXT_NAME_ONE=one
CLUSTER_CONTEXT_NAME_TWO=two

if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME_ONE=$1
  CLUSTER_CONTEXT_NAME_TWO=$2
  echo "$SCRIPT_NAME using provided cluster names of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
else
  echo "$SCRIPT_NAME using default cluster names of $CLUSTER_CONTEXT_NAME_ONE and $CLUSTER_CONTEXT_NAME_TWO"
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

SAVED_PRE_OKE=`pwd`
cd $COMMON_DIR/oke-setup
bash ./oke-cluster-destroy.sh one
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "oke-cluster-destroy one returned an error, unable to continue"
  exit $RESP
fi

bash ./oke-cluster-destroy.sh two
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "oke-cluster-destroy two returned an error, unable to continue"
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

exit 0