#!/bin/bash -f

if [ $# -lt 2 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires two arguments, the name of the log to process and the name of the containg log group"
  exit -1
fi
LOG_NAME=$1
LOG_GROUP_NAME=$2
LOG_NAME_CAPS=`bash ../settings/to-valid-name.sh $LOG_NAME`
LOG_GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $LOG_GROUP_NAME`
LOG_OCID_NAME=LOG_"$LOG_NAME_CAPS"_IN_LOG_GROUP_"$LOG_GROUP_NAME_CAPS"_OCID
echo $LOG_OCID_NAME