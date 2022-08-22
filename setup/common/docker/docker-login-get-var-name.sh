#!/bin/bash -f
if [ $# -eq 0 ]
then
  SCRIPT_NAME=`basename $0`
  echo "$SCRIPT_NAME requires arguments :"
  echo "  1st arg name of the OCIR Host to log into e.g. lhr.ocir.io"
  exit 1
fi
OCIR_HOST_NAME=$1

echo `bash ../settings/to-valid-name.sh "DOCKER_LOGIN_COUNT_""$OCIR_HOST_NAME"`
