#!/bin/bash -f
export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME  No existing settings cannot continue"
    exit 10
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi


CURRENT_GIT_BRANCH=`git branch --show-current`
COMPILE_DIR=`pwd`

if [ -z "$GIT_BRANCH_TO_COMPILE" ]
then
  echo "GIT_BRANCH_TO_COMPILE not set, retaining current branch of $CURRENT_GIT_BRANCH"
else
  MATCHING_GIT=`git branch -a --list | grep "$GIT_BRANCH_TO_COMPILE" | wc -l`
  if [ "$MATCHING_GIT" = 0 ]
  then
    echo "Can't locate git branch $GIT_BRANCH_TO_COMPILE for directory $COMPILE_DIR "
    exit 100
  else
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="y"
      echo "Auto confirm is enabled, Do you want to switch to git branch $GIT_BRANCH_TO_COMPILE to compile $COMPILE_DIR  defaulting to $REPLY"
    else
      read -p "Do you want to switch to git branch $GIT_BRANCH_TO_COMPILE to compile $COMPILE_DIR (y/n) ? " REPLY
    fi
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
      echo "OK, remaining in current branch $CURRENT_GIT_BRANCH for compiling $COMPILE_DIR"
    else
      echo "Found git branch $GIT_BRANCH_TO_COMPILE checking it out and re-pulling"
      git checkout $GIT_BRANCH_TO_COMPILE
      git pull 
      echo "Switched from git branch $CURRENT_GIT_BRANCH to $GIT_BRANCH_TO_COMPILE"
    fi
  fi
fi