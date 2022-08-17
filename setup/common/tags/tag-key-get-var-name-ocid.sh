#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -lt 2 ]
then
  echo "$SCRIPT_NAME requires two arguments:"
  echo "  1st arg the name of the containeg tag namespace"
  echo "  2nd arg the name of the tag key"
  exit 1
fi
TAG_NS_NAME=$1
TAG_KEY_NAME=$2
bash ../settings/to-valid-name.sh  "TAG_KEY_"$TAG_KEY_NAME"_IN_TAG_NS_"$TAG_NS_NAME"_OCID"