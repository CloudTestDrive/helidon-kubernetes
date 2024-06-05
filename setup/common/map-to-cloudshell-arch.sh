#!/bin/bash -f

# checks that you are using the requested architecture

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME, Missing arguments :"
    echo "  1st argument is the name of the input architecture, e.g. armv7, amd64"
    exit -1 
fi
INPUT_ARCH=`echo $1 | tr A-Z a-z | sed -e 's/-/_/g'`

case "$INPUT_ARCH" in 
	"aarm64"|"arm64")
		echo "aarm64"
		exit 0
	"x_86_64"|"amd64")
	    echo "x_86_64"
	    exit 0
	*)
		echo "Unknown input architecture of $INPUT_ARCH, this can't be mapped to a known cloud chall architecture"
		exit -1
esac