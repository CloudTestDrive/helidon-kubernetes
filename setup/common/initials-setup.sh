#!/bin/bash -f
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else
  echo "$SCRIPT_NAME Creating new settings information"
fi

if [ -z "$USER_INITIALS_REUSED" ]
  then
  INVALID=true
  
  while [ true ]
  do
    echo "Please can you enter your initials - use lower case a-z only and no spaces, for example if your name is John Smith your initials would be js. This will be used to do things like name the database"

    read USER_INITIALS
  
    if [ -z "$USER_INITIALS" ]
    then
      echo "You actually need to enter your initials, please try again"
      continue
    fi
  
    if [[ "$USER_INITIALS" =~ [^a-z] ]]
    then 
      echo 'Non a-z characters found, please retry again'
      continue
    fi
  
    echo "Your intials are $USER_INITIALS"
    break ;

  done
  echo USER_INITIALS=$USER_INITIALS >> $SETTINGS
  echo USER_INITIALS_REUSED=false >> $SETTINGS
else
  echo "Initials already set to $USER_INITIALS will re-use them"
fi