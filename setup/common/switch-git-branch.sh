#!/bin/bash -f
CURRENT_GIT_BRANCH=`git branch --show-current`

if [ -z "$GIT_BRANCH_TO_COMPILE" ]
then
  echo "GIT_BRANCH_TO_COMPILE not set, retaining current branch of $CURRENT_GIT_BRANCH"
else
  MATCHING_GIT=`git branch -a --list | grep "$GIT_BRANCH_TO_COMPILE" | wc -l`
  if [ "$MATCHING_GIT" = 0 ]
  then
    echo "Can't locate git branch $GIT_BRANCH_TO_COMPILE "
    exit 100
  else
    echo "Found git branch $GIT_BRANCH_TO_COMPILE checking it out and re-pulling"
  git checkout $GIT_BRANCH_TO_COMPILE
  git pull 
  echo "Switched from git branch $CURRENT_GIT_BRANCH to $GIT_BRANCH_TO_COMPILE"
  fi
fi