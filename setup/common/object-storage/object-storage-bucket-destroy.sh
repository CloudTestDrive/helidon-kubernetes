#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
then
  echo "$SCRIPT_NAME Missing arguments you must provide:"
  echo "  1st argument - name of the bucket to destroy - this must meet the object storage bucket names restrictions"
  echo "Optional"
  echo " 2nd argument - set to retain if you want to stop the delete if there are objects in the bucket - defaults to deleting bucket and contents"
fi

BUCKET_NAME=$1

CLEAR_BUCKET_FLAG="--empty"
if [ $# -ge 1 ]
then
  if [ $1 = "retain" ]
  then
    echo "Will not delete a non empty bucket"
    CLEAR_BUCKET=
  else 
    echo "Will delete bucket and any contents"
  fi
else  
  echo "Defaulting to deleting bucket and any contents"
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


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

BUCKET_REUSED_NAME=`bash ../settings/to-valid-name.sh "$BUCKET_NAME"_REUSED`
BUCKET_REUSED="${!BUCKET_REUSED_NAME}"
if [ -z "$BUCKET_REUSED" ]
then
  echo "No resuse information for $BUCKET_NAME, unsafe to proceed"
  exit 0
else
  echo "Bucket $BUCKET_NAME reuse info found, continuing"
fi
if [ "$BUCKET_REUSED" = "true" ]
then
  echo "Bucket $BUCKET_NAME not created by these scripts - will exit"
  exit 0
else
  echo "Bucket $BUCKET_NAME created by these scripts - will delete"
  oci os bucket delete --bucket-name $BUCKET_NAME $CLEAR_BUCKET_FLAG --force
fi



BUCKET_OCID_NAME=`bash ../settings/to-valid-name.sh "$BUCKET_NAME"_OCID`
bash ../delete-from-saved-settings.sh $BUCKET_OCID_NAME
bash ../delete-from-saved-settings.sh $BUCKET_REUSED_NAME
