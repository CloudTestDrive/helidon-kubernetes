#!/bin/bash -ff
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "the name of the key to convert"
  exit 1
fi
TAG_NS_NAME=$1
bash ../settings/to-valid-name.sh  "TAG_NS_"$TAG_NS_NAME"_UNDELETED"