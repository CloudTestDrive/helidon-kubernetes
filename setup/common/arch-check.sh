#!/bin/bash -f

# checks that you are using the requested architecture

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME, Missing arguments :"
    echo "  1st argument is the name of the requested architecture, e.g. armv7, amd64"
    echo "Optional"
    echo "  subsequent arguments are names of other usable architectures"
    exit -1 
fi
REQUIRED_ARCH=`echo $1 | tr A-Z a-z | sed -e 's/-/_/g -e 's/ //g' -e 's/\t//g'`

CURRENT_ARCH=`uname -m | tr A-Z a-z | sed -e 's/-/_/g -e 's/ //g' -e 's/\t//g'`

if [ "$CURRENT_ARCH" = "$REQUIRED_ARCH" ]
then
	echo "Machine architechure $CURRENT_ARCH is the required architecture"
	exit 0
else
    echo "Machine architechure $CURRENT_ARCH does not match the required architecture of $REQUIRED_ARCH"
    exit -10
fi