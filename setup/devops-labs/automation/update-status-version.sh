#/bin/bash -f 
REQUIRED_ARGS_COUNT=4
if [ $# -lt $REQUIRED_ARGS_COUNT ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires $REQUIRED_ARGS_COUNT arguments"
  echo "The current version mumber"
  echo "The new version number"
  echo "The full path of the status resource file"
  echo "The git branch we're working on"
  exit -1
fi
STATUS_VERSION_ORIGIONAL=$1
STATUS_VERSION_UPDATED=$2
STATUS_RESOURCE=$3
GIT_BRANCH_NAME=$4

# switch to the directory
cd `dirname "$STATUS_RESOURCE"`

echo "Updating version number in $STATUS_RESOURCE to $STATUS_VERSION_UPDATED from$STATUS_VERSION_ORIGIONAL"
bash $COMMON_DIR/update-file.sh  "$STATUS_VERSION_UPDATED" "$STATUS_VERSION_ORIGIONAL" "$STATUS_RESOURCE"

echo "Updating local repo and uploading to remote repo"
git add .
git commit -a -m "Updated version to $STATUS_VERSION_UPDATED"
git push devops $GIT_BRANCH_NAME