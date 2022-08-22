#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME requires arguments :"
  echo "  1st arg name of the OCIR Host to log out from e.g. lhr.ocir.io"
  exit 1
fi
OCIR_HOST_NAME=$1

if [ $# -gt 1 ]
then
  PROVIDED_AUTH_TOKEN="$2"
else
  unset PROVIDED_AUTH_TOKEN
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi


echo "Checking for logins to $OCIR_HOST_NAME"
LOG_IN_COUNT_NAME=`bash ./docker-login-get-var-name.sh $OCIR_HOST_NAME`
LOG_IN_COUNT="${!LOG_IN_COUNT_NAME}"
if [ -z "$LOG_IN_COUNT" ]
then
  echo "No existing login found for OCIR $OCIR_HOST_NAME , nothing to log out of"
  exit 0
fi
if [ "$LOG_IN_COUNT" = 0 ]
then
  echo "No existing login count for OCIR $OCIR_HOST_NAME is $LOG_IN_COUNT nothing to log out of, just tidy up"
  bash ../delete-from-saved-settings.sh $LOG_IN_COUNT_NAME
  exit 0
else
  echo "There are $LOG_IN_COUNT logins on OCIR OCIR $OCIR_HOST_NAME"
fi
let "LOG_IN_COUNT = $LOG_IN_COUNT - 1"
bash ../delete-from-saved-settings.sh $LOG_IN_COUNT_NAME
if [ "$LOG_IN_COUNT" = 0 ]
then
  echo "No remaining logins, doing docker logout"
  docker logout $OCIR_HOST_NAME
else
  echo "After deductrion for this script run there are $LOG_IN_COUNT remaining logins on OCIR $OCIR_HOST_NAME remaining logged in"
  echo "$LOG_IN_COUNT_NAME=$LOG_IN_COUNT" >> $SETTINGS
  exit 0
fi
