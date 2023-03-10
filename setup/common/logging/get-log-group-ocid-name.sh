#!/bin/bash -f

if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument, the name of the log group to process"
  exit -1
fi
LOG_GROUP_NAME=$1
LOG_GROUP_NAME_CAPS=`bash ../settings/to-valid-name.sh $LOG_GROUP_NAME`
LOG_GROUP_OCID_NAME=LOG_GROUP_"$LOG_GROUP_NAME_CAPS"_OCID
echo $LOG_GROUP_OCID_NAME