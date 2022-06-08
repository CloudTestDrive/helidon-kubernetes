#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Settings file $SETTINGS located"
  else 
    echo "No settings file cannot continue"
    exit 10
fi


# ensure that we have a limit on how many times to loop for the check
if [ -z "$WAIT_LOOP_COUNT" ]
then 
  WAIT_LOOP_COUNT=180
fi

for i in {1..$WAIT_LOOP_COUNT}
do
  echo -n "Testing $i at " 
  date +'%H:%M:%S'
  SERVICES_READY=true
  # remove any previous values that may have been set
  for varName in "$@"
  do
    unset "$varName"
  done
  # get the latest settings
  source $SETTINGS
  for varName in "$@"
  do
    echo -n "Testing for $varName - "
    if [ -z "${!varName}" ]
    then
      echo "Not present"
      SERVICES_READY=false
    else
      echo "Found it, value is ${!varName}"
    fi
  done
  
  if [ "$SERVICES_READY" = "true" ]
  then
    echo "Required services are indicating ready"
    break ;
  else
    echo "Waiting for the next test "
    sleep 10
    continue ;
  fi
done

# check if the loop finished, if it did then $SERVICES_READY will be true
if [ "$SERVICES_READY" = "true" ]
then
  exit 0
else
  echo "PROBLEM, one of more services are not ready after $WAIT_LOOP_COUNT test loops"
  exit 1
fi