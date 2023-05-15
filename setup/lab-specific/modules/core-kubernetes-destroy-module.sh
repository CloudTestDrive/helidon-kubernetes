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

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi
# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

# be sure to remove the k8s ingress controller, sometimes removing the 
# destroying the cluster or the ingress-nginx namespace leaves this around 
# and that blocks shutting down the vcn

echo "Removing ingress LB"
helm uninstall ingress-nginx --kube-context $CLUSTER_CONTEXT_NAME --namespace ingress-nginx 

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
bash ./oke-cluster-destroy.sh $CLUSTER_CONTEXT_NAME
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