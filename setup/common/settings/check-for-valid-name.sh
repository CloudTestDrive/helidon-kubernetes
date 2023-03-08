#!/bin/bash -f

if [ "$#" -lt 1 ]
then  
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument the word to check"
  exit -1
fi

ORIG=$1
UPPER=`echo $ORIG | tr a-z A-Z | sed -e 's:/:_:' | sed -e 's/^_//' | sed -e 's/-/_/g'  | sed -e 's/\./_/g`
if [ $ORIG = $UPPER ]
then
  exit 0
else
  exit 1
fi