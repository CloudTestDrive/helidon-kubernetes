#!/bin/bash -f

SAVED_PWD=`pwd`

cd $KUBERNETES_LABS_DIR

bash ./kubernetes-services-destroy.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Kubernetes services destroy returned an error, unable to continue"
  exit $RESP
fi

exit 0