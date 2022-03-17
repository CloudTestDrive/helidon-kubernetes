#!/bin/bash -f

# the DIR based locations must have been set before calling this script
SAVED_PWD=`pwd`

cd $COMMON_DIR

bash ./download-step.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "Downloading step returned an error, unable to continue"
  exit $RESP
fi

bash ./check-minimum-resources.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "Check minimum resources (base resources) returned an error, unable to continue"
  exit $RESP
fi

bash ./core-environment-setup.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "core setup returned an error, unable to continue"
  exit $RESP
fi

bash ./kubernetes-setup.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "kubernetes cluster setup returned an error, unable to continue"
  exit $RESP
fi

bash ./image-environment-setup.sh
RESP=$?
if ( "$RESP" -ne 0 ]
then
  echo "image environment returned an error, unable to continue"
  exit $RESP
fi

exit 0