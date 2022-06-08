#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ -z $USER_OCID ]
  then
    echo 'No user ocid, unable to continue - have you run the user-identity-setup.sh script ?'
fi

if [ -z $AUTH_TOKEN_REUSED ]
then
  echo "No existing auth token."
else
  echo "Your auth token has already been set, it will be reused, to remove it run the auth-token-destroy.sh script"
  exit 0
fi

if [ -z $AUTH_TOKEN_OCID ]
then
  echo "No existing auth token OCID."
else
  echo "Your auth token has already been set, to remove it run the auth-token-destroy.sh script"
  exit 1
fi

echo "Checking region"
OCI_HOME_REGION_KEY=`oci iam tenancy get --tenancy-id $OCI_TENANCY | jq -j '.data."home-region-key"'`

OCI_HOME_REGION=`oci iam region list | jq -e  ".data[]| select (.key == \"$OCI_HOME_REGION_KEY\")" | jq -j '.name'`

if [ $OCI_REGION = $OCI_HOME_REGION ]
then
  echo "You are in your home region and this script will continue"
else
  echo "You need to run this script in your home region of $OCI_HOME_REGION, you are running it in $OCI_REGION"
  echo "Please switch to your OCI home region and re-run this script"
  exit 1
fi

AUTH_TOKEN_COUNT=`oci iam auth-token list --user-id $USER_OCID --all | jq -e '.data | length'`

if [ -z $AUTH_TOKEN_COUNT ]
then
  AUTH_TOKEN_COUNT=0
fi

if [ $AUTH_TOKEN_COUNT -eq 2 ]
then
  echo 'You are already at the maximum number of auth tokens, you must reuse one (r) in which case you must also know its'
  echo 'value or quit and manually delete an unneeded existing one to continue (d)'
  read -p 'Quit and delete an existing token (d) or reuse an existing one (r)' REPLY 
  if [[ ! $REPLY =~ ^[Rr]$ ]]
  then
    echo 'OK, exiting, you can delete an unneeded auth token by going to the  user details'
    echo 'page (click on the "shadow" person upper left then the user name) -> Auth Tokens in the resources'
    echo 'then click on the three dots menu for the auth token you want to delete and chose delete'
    echo ' You can then re-run this script'
    exit 2
  else 
    echo "OK, reusing existing token"
    REUSE_TOKEN=true
  fi
else
  if [ $AUTH_TOKEN_COUNT -eq 0 ]
  then
    echo "No existing auth tokens, will create a new one"
    REUSE_TOKEN=false
  else
    echo 'Do you want to re-use an existing auth token (r) if not then the script will let you create a new one (c) '
    echo 'To reuse an existing one you will need to enter the auth tokens OCID (User details page -> Auth Tokens -> Three dots menu -> Copy OCID)'
    echo 'To reuse an existing auth token you will also need to know its value for later use, if you do not know the value then you will have to create a new one'
    
    if [ "$AUTO_CONFIRM" = true ]
    then
      REPLY="c"
      echo "Auto confirm is enabled, reuse or create defaulting to $REPLY"
    else
     read -p 'Create a new auth token (c) or reuse an existing one (r)' REPLY 
    fi
    if [[ ! $REPLY =~ ^[Rr]$ ]]
    then
      echo "Will create a token"
      REUSE_TOKEN=false
    else
      echo "Will reuse a token"
      REUSE_TOKEN=true
    fi
  fi
fi

if [ $REUSE_TOKEN = true ]
then
  echo 'Reusing an auth token'
  echo 'Do you want to save the auth token value to make later reuse easier ?'
  echo 'This will make doing the lab easier as otherwise you will have to re-enter it when its needed, but '
  echo 'it is not good security practice, the token will not be accessible unless logged in as'
  echo 'you so its not a major risk, but you should not do this if you are using this tenancy for'
  echo 'anything other than lab work' 
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, save token defaulting to $REPLY"
  else
    read -p 'Save the auth token ?' REPLY 
  fi
  if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
    read -p 'OK, please enter the auth token value, if you do now know it enter an empty line and the script will exit' AUTH_TOKEN
    if [ -z $AUTH_TOKEN ]
    then
      echo "Nothing entered, this script will exit and no changes have been made, you can re-run it"
      exit 1
    fi
    echo "AUTH_TOKEN_REUSED=true" >> $SETTINGS
    echo "AUTH_TOKEN='$AUTH_TOKEN'" >> $SETTINGS
  else
    echo "AUTH_TOKEN_REUSED=true" >> $SETTINGS
  fi
else
  echo 'Creating a new auth token for you'
  AUTH_TOKEN_JSON=`oci iam auth-token create --description 'Labs' --user-id $USER_OCID`
  AUTH_TOKEN=`echo $AUTH_TOKEN_JSON | jq -j '.data.token'`
  AUTH_TOKEN_OCID=`echo $AUTH_TOKEN_JSON | jq -j '.data.id'`
  # wait ubntiol the token is actove
  AUTH_TOKEN_STATE="INACTIVE"
  echo "Checking for active token with OCID $AUTH_TOKEN_OCID"
  while [ "$AUTH_TOKEN_STATE" != "ACTIVE" ]
  do
    AUTH_TOKEN_STATE=`oci iam auth-token list  --user-id $USER_OCID --all | jq -j ".data[] | select (.id==\"$AUTH_TOKEN_OCID\") | .\"lifecycle-state\""`
    echo "Auth token state is $AUTH_TOKEN_STATE"
    if [ "$AUTH_TOKEN_STATE" != "ACTIVE" ]
    then
      echo "Waiting to check auth token state"
      sleep 10
    fi
  done
  echo "AUTH_TOKEN_REUSED=false" >> $SETTINGS
  echo "AUTH_TOKEN_OCID=$AUTH_TOKEN_OCID" >> $SETTINGS 
  
  echo "Your new auth token is $AUTH_TOKEN It is critical that you do not lose this information so please take note of it."
  echo "if needed you can delete the token by running the auth-token-destroy.sh script and then create a new one, but you will have"
  echo "to repeat all of the processes that use it if you do."
  echo 'Do you want to save the auth token value to make later reuse easier ?'
  echo 'This will make doing the lab easier as otherwise you will have to re-enter it when its needed, but '
  echo 'it is not good security practice, the token will not be accessible unless logged in as'
  echo 'you so its not a major risk, but you should not do this if you are using this tenancy for'
  echo 'anything other than lab work' 
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, save token defaulting to $REPLY"
  else
    read -p 'Save the auth token ?' REPLY 
  fi
  if [[ ! $REPLY =~ ^[Nn]$ ]]
  then
    echo "AUTH_TOKEN='$AUTH_TOKEN'" >> $SETTINGS
    echo "Your new auth token is has been saved in the $SETTINGS file its a good idea for you to"
    echo "still take note of it as you may want it for other situations."
  fi
fi