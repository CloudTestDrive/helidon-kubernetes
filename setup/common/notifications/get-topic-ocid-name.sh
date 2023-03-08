#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the topic to process"
  exit -1
fi
TOPIC_NAME=$1
TOPIC_NAME_CAPS=`bash ../settings/to-valid-name.sh $TOPIC_NAME`
TOPIC_OCID_NAME=TOPIC_"$TOPIC_NAME_CAPS"_OCID
echo $TOPIC_OCID_NAME