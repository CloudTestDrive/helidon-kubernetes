#!/bin/bash -f
SCRIPT_NAME=`basename $0`

if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME requires arguments :"
  echo "  1st arg name of the OCIR Host to log into e.g. lhr.ocir.io"
  echo "Optional"
  echo "  2nd arg the auth token to use for the login - make sure this is quoted when you call this script or the shall may do horrible things"
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

if [ -z "$PROVIDED_AUTH_TOKEN" ]
then
  echo "Using provided auth token"
else
  AUTH_TOKEN="$PROVIDED_AUTH_TOKEN"
fi
if [ -z $AUTH_TOKEN ]
then
  echo "$SCRIPT_NAME Your auth token has not been set, you need to provide it as the 2nd argument to this script or run the auth-token-setup.sh script and save the token before you can run this script"
  exit 1
fi
echo "Checking for logins to $OCIR_HOST_NAME"
LOG_IN_COUNT_NAME=`bash ./docker-login-get-var-name.sh $OCIR_HOST_NAME`
LOG_IN_COUNT="${!LOG_IN_COUNT_NAME}"
if [ -z "$LOG_IN_COUNT" ]
then
  LOG_IN_COUNT=0
fi
if [ "$LOG_IN_COUNT" = 0 ]
then
  echo "No existing login found for OCIR $OCIR_HOST_NAME , proceeding"
else
  echo "Already logged into OCIR $OCIR_HOST_NAME $LOG_IN_COUNT times, updating count"
  let "LOG_IN_COUNT = $LOG_IN_COUNT + 1"
  bash ../delete-from-saved-settings.sh $LOG_IN_COUNT_NAME
  echo "$LOG_IN_COUNT_NAME=$LOG_IN_COUNT" >> $SETTINGS
  exit 0
fi


OCI_USERNAME=`oci iam user get --user-id $USER_OCID | jq -j '.data.name'`

OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`
MAX_LOGIN_ATTEMPTS=10
DOCKER_LOGIN_FAILED_SLEEP_TIME=30

echo "About to docker login for $LOGIN_REASON_NAME to $OCIR_HOST_NAME and object storage namespace $OBJECT_STORAGE_NAMESPACE with username $OCI_USERNAME using your auth token as the password"
echo "Please ignore warnings about insecure password storage"
echo "It can take a short while for a new auth token to be propogated to the OCIR service, so if the docker login fails do not be alarmed the script will retry after a short delay."
for i in  `seq 1 $MAX_LOGIN_ATTEMPTS` 
do
  echo -n $AUTH_TOKEN | docker login $OCIR_HOST_NAME --username=$OBJECT_STORAGE_NAMESPACE/$OCI_USERNAME --password-stdin
  RESP=$?
  echo "Docker Login resp is $RESP"
  if [ $RESP = 0 ]
  then
    echo "docker login to $OCIR_HOST_NAME suceeded on attempt $i, continuing"
    break ;
  else
    echo "docker login to $OCIR_HOST_NAME failed on attempt $i, retrying after pause"
    sleep $DOCKER_LOGIN_FAILED_SLEEP_TIME
  fi
  if [ $i -eq $MAX_LOGIN_ATTEMPTS ]
  then
    echo "Unable to complete docker login after 12 attempts, cannot continue"
    exit 10
  fi
done
LOG_IN_COUNT=1
echo "$LOG_IN_COUNT_NAME=$LOG_IN_COUNT" >> $SETTINGS
