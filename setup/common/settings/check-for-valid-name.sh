#!/bin/bash -f

if [ "$#" -lt 1 ]
then
  echo "The check for valid name script requires one argument the word to check"
  exit -1
fi

ORIG=$1
UPPER=`echo $ORIG | tr a-z A-Z | sed -e 's:/:_:'`
if [ $ORIG = $UPPER ]
then
  exit 0
else
  exit 1
fi