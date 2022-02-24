#!/bin/bash -f

if [ "$#" -lt 1 ]
then
  echo "The to valid name script requires one argument the word to convert"
  exit -1
fi

ORIG=$1
UPPER=`echo $ORIG | tr a-z A-Z | sed -e 's:/:_:`
echo $UPPER