#!/bin/bash -ff
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
then
  echo "$SCRIPT_NAME requires one argument:"
  echo "your user initials"
  exit 1
fi
USER_INITIALS=$1
echo  "$USER_INITIALS"OCIOSKServiceMeshPolicy