#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the OKE cluster to process"
  exit -1
fi
OKE_NAME=$1
OKE_NAME_CAPS=`bash ../settings/to-valid-name.sh $OKE_NAME`
OKE_REUSED_NAME=OKE_"$OKE_NAME_CAPS"_REUSED
echo $OKE_REUSED_NAME