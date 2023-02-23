#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department, e.g. tg"
    exit -1 
fi
DEPARTMENT=$1
# reset the configuration flag - there won;t be anythign we can in the curren git repo as it will have been reset
bash ../common/delete-from-saved-settings.sh REPO_CONFIGURED_FOR_SERVICES
bash ./configure-downloaded-git-repo.sh $DEPARTMENT