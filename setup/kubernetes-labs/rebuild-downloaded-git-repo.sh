#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1

bash ./unconfigure-downloaded-git-repo.sh $DEPARTMENT
bash ./configure-downloaded-git-repo.sh $DEPARTMENT