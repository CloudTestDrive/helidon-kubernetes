#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the artifact repo to process"
  exit -1
fi
OCIR_NAME=$1
OCIR_NAME_CAPS=`bash ../settings/to-valid-name.sh $OCIR_NAME`
OCIR_REUSED_NAME=OCIR_"$OCIR_NAME_CAPS"_REUSED
echo $OCIR_REUSED_NAME