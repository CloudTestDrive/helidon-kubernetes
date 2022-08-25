#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -lt 3 ]
then
  echo "$SCRIPT_NAME requires three arguments:"
  echo "  1st the name of the dynamic group to create"
  echo "  2nd the description of the dynamic group (which needs to be quoted)"
  echo "  3rd the resource type of the dynamic group e.g. devopsbuildpipeline"
  echo "Optional"
  echo "  4th and subsequent args are a list of additional resource types, any of which will match"
  exit 1
fi

GROUP_NAME=$1
GROUP_DESCRIPTION=$2

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

source $SETTINGS

# work out what the validation should look like
VALUES_START_ARG=3
GROUP_RULE='ANY {'
for i in `seq $VALUES_START_ARG $#`
  do
    if [ $i -gt $VALUES_START_ARG ]
    then
      GROUP_RULE="$GROUP_RULE"","
    fi
    GROUP_RULE="$GROUP_RULE""resource.type = '${!i}'"
  done
  GROUP_RULE="$GROUP_RULE"'}'

echo "GROUP_RULE is :\n$GROUP_RULE"

bash ./dynamic-group-setup.sh "$GROUP_NAME" "$GROUP_DESCRIPTION" "$GROUP_RULE"