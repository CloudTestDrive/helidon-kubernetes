#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the ocir repo to process"
  exit -1
fi
OCIR_NAME=$1
OCIR_NAME_CAPS=`bash ../settings/to-valid-name.sh $OCIR_NAME`
OCIR_OCID_NAME=OCIR_"$OCIR_NAME_CAPS"_OCID
echo $OCIR_OCID_NAME