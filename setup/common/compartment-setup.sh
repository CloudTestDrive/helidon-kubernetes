#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


COMPARTMENT_NAME=CTDOKE

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, using defaults"
fi


if [ -z $COMPARTMENT_REUSED ]
then
  echo "No reuse information for compartment"
else
  echo "This script has already configured compartment details, exiting"
  exit 3
fi


# do we have an existing compartment to use ?
if [ -z $COMPARTMENT_OCID ]
then
  # no previous compartment set
  # has someone specified a parent compartment override previously of so let's try and get the name to use ?
  if [ -z $COMPARTMENT_PARENT_OCID ]
  then
    # no, default to creating in the root compartment
    COMPARTMENT_PARENT_OCID=$OCI_TENANCY
    echo "Parent is tenancy root"
  fi

  TENANCY_NAME=`oci iam tenancy get --tenancy-id=$OCI_TENANCY | jq -j '.data.name'`
  COMPARTMENT_PARENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_PARENT_OCID | jq -j '.data.name' | sed -e 's/"//g'`

  if [ -z $COMPARTMENT_PARENT_NAME ]
  then
    echo "Unable to locate details for specified parent compoartment with OCID $COMPARTMENT_PARENT_OCID cannot contiue"
    echo "Please edit the settings file $SETTINGS and ensure that the COMPARTMENT_PARENT_OCID variable contains a valid compartment OCID for this tenancy"
    exit 99
  fi

  if [ $COMPARTMENT_PARENT_NAME = $TENANCY_NAME ]
  then
    PARENT_NAME="Tenancy root"
  else 
    PARENT_NAME="$COMPARTMENT_PARENT_NAME sub compartment"
  fi

  echo "This script will create a compartment called $COMPARTMENT_NAME for you if it doesn't exist, this will be in the $PARENT_NAME. If a compartment with the same name already exists you can re-use change the name to create or re-use a different compartment."

  echo "If you want to use somewhere different from $PARENT_NAME as the parent of the compartment you are about to create (or re-use) then enter n, if you want to use $PARENT_NAME for your parent then enter y"
  read -p "Use the $PARENT_NAME (y/n) ? " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "You need to edit the $SETTINGS file and add a line of the form"
    echo 'COMPARTMENT_PARENT_OCID=<OCID>'
    echo 'replacing <OCID> with the OCID of the parent compartment to be used when creating the compartment'
    echo 'Then re-run this script'
    exit 1
  fi

  echo "We are going to create or if it already exists reuse use a compartment called $COMPARTMENT_NAME in $PARENT_NAME, if you want you can change the compartment name from $COMPARTMENT_NAME - this is not recommended and you will need to remember to use a different name in the lab." 
  read -p "Do you want to use $COMPARTMENT_NAME as the compartment name  (y/n) ? " REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, this isn't the best of ideas, please enter the new name for your compartment, it must be a single word"
    read COMPARTMENT_NAME
    if [ -z "$COMPARTMENT_NAME" ]
    then
      echo "You do actually need to enter the new name for the compartment, exiting"
      exit 1
    fi
  else     
    echo "OK, going to use $COMPARTMENT_NAME as the compartment name"
  fi

  # OK, actual do the work.

  COMPARTMENT_OCID=`oci iam compartment list --name $COMPARTMENT_NAME --compartment-id $COMPARTMENT_PARENT_OCID | jq -j '.data[0].id'`
  # does it already exist
  if [ -z $COMPARTMENT_OCID ]
  then
    echo "Compartment $COMPARTMENT_NAME, doesn't already exist in $PARENT_NAME, creating it"
    # Ideally we'd use these flags for have thew OCI command wait for us, but that seems broken at the moment
    #  --wait-for-state ACTIVE --wait-interval-seconds 10
    COMPARTMENT_OCID=`oci iam compartment create --name $COMPARTMENT_NAME --compartment-id $COMPARTMENT_PARENT_OCID --description "Labs compartment" | jq -j '.data.id'`
    if [ -z $COMPARTMENT_OCID ]
    then
      echo "The compartment has not been created for some reason, cannot continue"
      exit 3
    fi
    echo "Created compartment $COMPARTMENT_NAME in $PARENT_NAME It's OCID is $COMPARTMENT_OCID"
    echo "COMPARTMENT_OCID=$COMPARTMENT_OCID" >> $SETTINGS
    echo "COMPARTMENT_REUSED=false" >> $SETTINGS
    echo "It may take a short while before new compartment has propogated and the web UI reflects this"
    # Wait for the compartment to exist, there have been cases where the --wait-for-state has not worked and that had broken downstream stages
    COMPARTMENT_STATUS="WATTING"
    echo "Checking for active compartment state"
    while [ "$COMPARTMENT_STATUS"  !=  "ACTIVE" ]
    do
      echo "Retrieving compartment state"
      COMPARTMENT_STATUS_RESP=`oci iam compartment get --compartment-id $COMPARTMENT_PARENT_OCID 2>&1`
      echo "Returned info is \n$COMPARTMENT_STATUS_RESP"
      COMPARTMENT_STATUS_CODE=`echo $COMPARTMENT_STATUS_RESP | jq -j '.status'`
      if [ "$COMPARTMENT_STATUS_CODE" = "null" ]
      then
        echo "null status found, clearing"
        COMPARTMENT_STATUS_CODE=""
      fi
      if [ -z "$COMPARTMENT_STATUS_CODE" ] 
      then
        echo "No error status returned, checking for active status"
      else
        echo "Got status $COMPARTMENT_STATUS_CODE, re-checking soon"
        sleep 5
        continue
      fi
      
      COMPARTMENT_STATUS=`echo $COMPARTMENT_STATUS_RESP | jq -j '.data."lifecycle-state"'`
      echo "Status is $COMPARTMENT_STATUS"
      if [ "$COMPARTMENT_STATUS" = "ACTIVE" ]
      then
        echo "Compartment is active, continuing"
      else
        echo "Waiting for active compartment state"
        sleep 5
      fi
    done
    echo "Compartment $COMPARTMENT_NAME in $PARENT_NAME is now ready for use"
  else
    echo "Compartment $COMPARTMENT_NAME already exists in $PARENT_NAME, do you want to re-use it (y/n) ?"
    read CONFIRM
    if [[ ! $CONFIRM =~ ^[Yy]$ ]]
    then
      echo "OK, This script is about to exit, re-run it entering a compartment name different from $COMPARTMENT_NAME"
      exit 1
    else
      echo "OK, going to reuse compartment $COMPARTMENT_NAME in $PARENT_NAME" 
      echo "COMPARTMENT_OCID=$COMPARTMENT_OCID" >> $SETTINGS
      echo "COMPARTMENT_REUSED=true" >> $SETTINGS
    fi
  fi
else
  # We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
  COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`
  if [ -z $COMPARTMENT_NAME ]
  then
    echo "Unable to locate compartment for provided OCID $COMPARTMENT_OCID"
    echo "Please check that the value of COMPARTMENT_OCID in $SETTINGS is correct if nor remove or replace it"
    exit 5
  else
    echo "Located compartment named $COMPARTMENT_NAME with pre-specified OCID of $COMPARTMENT_OCID, will use this compartment"
    # Flag this as reused and refuse to destroy it
    echo "COMPARTMENT_REUSED=true" >> $SETTINGS
  fi
fi

