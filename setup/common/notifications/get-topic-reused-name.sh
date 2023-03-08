#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "This script requires one argument, the name of the topic to process"
  exit -1
fi
TOPIC_NAME_CAPS=`bash ../settings/to-valid-name.sh $TOPIC_NAME`
TOPIC_REUSED_NAME=`bash ./get-topic-reused-name.sh $TOPIC_NAME`
echo $TOPIC_REUSED_NAME