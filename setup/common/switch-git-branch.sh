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

# Is seems that the version of the git command in the cloud shell has been reverted to an  older version, so let's define a command to test versions
# This is the vercomp examnple at https://www.baeldung.com/linux/compare-dot-separated-version-string
vercomp() {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
CURRENT_GIT_VERSION=`git --version | sed -e 's/git//' -e 's/version//'  -e 's/ //g'`
MINGIT_SHOW_VERSION=2.22
vercomp $CURRENT_GIT_VERSION $MINGIT_SHOW_VERSION
VERDATA=$?
if [ $VERDATA -eq 2 ]
then
	echo "git version in use does not support git branch --show-current, reverting to grep based method"
	CURRENT_GIT_BRANCH=`git branch | grep '*' | cut -c 3-`
else 
	echo "git version in use supports git branch --show-current, using that"
	CURRENT_GIT_BRANCH=`git branch --show-current`
fi
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