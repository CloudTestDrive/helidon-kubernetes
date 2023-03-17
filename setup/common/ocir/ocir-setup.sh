#!/bin/bash -f


if [ $# -lt 1 ]
then
  SCRIPT_NAME=`basename $0`
  echo "The $SCRIPT_NAME script requires one argument"
  echo " the name of the ocir repo to create"
  echo "optionally"
  echo " if the repo will be public (true or false, defaults to false)"
  echo " if the repo is immutable (true or false, default false)"
  exit -1
fi
OCIR_REPO_NAME=$1
OCIR_REPO_PUBLIC=false
OCIR_REPO_IMMUTABLE=false
if [ $# -ge 2 ]
then
  OCIR_REPO_PUBLIC="$2"

fi

if [ "$OCIR_REPO_PUBLIC" != "true" ] && [ "$OCIR_REPO_PUBLIC" != "false" ]
then
  echo "You have provided an public flag that is not either true or false, you specified $OCIR_REPO_PUBLIC Unable to continue"
  exit 3
fi
if [ $# -ge 3 ]
then
  OCIR_REPO_IMMUTABLE="$2"

fi

if [ "$OCIR_REPO_IMMUTABLE" != "true" ] && [ "$OCIR_REPO_IMMUTABLE" != "false" ]
then
  echo "You have provided an immutable flag that is not either true or false, you specified $OCIR_REPO_IMMUTABLE Unable to continue"
  exit 3
fi
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


# get the possible reuse and OCID for the devops project itself
echo "Getting var names for OCIR repo $OCIR_REPO_NAME"
OCIR_REPO_OCID_NAME=`bash ./get-ocir-ocid-name.sh $OCIR_REPO_NAME`
OCIR_REPO_REUSED_NAME=`bash ./get-ocir-reused-name.sh $OCIR_REPO_NAME`

OCIR_REPO_REUSED="${!OCIR_REPO_REUSED_NAME}"

if [ -z $OCIR_REPO_REUSED ]
then
  echo "No resuse information, proceeding"
else
  echo "OCI Repo $OCIR_REPO_NAME has already been setup by this script, you can remove it and other repos using the ocir-destroy.sh script, that will also remove any existing images"
  exit 0
fi

echo "Checking for existing OCIR repo $OCIR_REPO_NAME"
OCIR_REPO_OCID=`oci artifacts container repository list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_REPO_NAME --all | jq -j '.data.items[0].id' `
if [ $OCIR_REPO_OCID = 'null' ]
then
# No existing repo for stock manager
  echo "Creating OCIR repo named $OCIR_REPO_NAME "
  OCIR_REPO_OCID=`oci artifacts container repository create --compartment-id $COMPARTMENT_OCID --display-name $OCIR_REPO_NAME --is-immutable "$OCIR_REPO_IMMUTABLE" --is-public "$OCIR_REPO_PUBLIC" --wait-for-state AVAILABLE | jq -j '.data.id'`
  echo "$OCIR_REPO_OCID_NAME=$OCIR_REPO_OCID" >> $SETTINGS 
  echo "$OCIR_REPO_REUSED_NAME=false" >> $SETTINGS
else
  if [ "$AUTO_CONFIRM" = true ]
  then
    REPLY="y"
    echo "Auto confirm is enabled, reuse repo $OCIR_REPO_NAME defaulting to $REPLY"
  else
    read -p "There is an existing OCIR repo $OCIR_REPO_NAME, do you want to re-use it (y/n) ?" REPLY
  fi
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, stopping script, the repo has not been reused, you need to re-run this script before doing any container image pushes"
    exit 1
  else     
    echo "OK, going to use reuse existing OCIR repo called $OCIR_REPO_NAME"
    echo "$OCIR_REPO_OCID_NAME=$OCIR_REPO_OCID" >> $SETTINGS 
    echo "$OCIR_REPO_REUSED_NAME=true" >> $SETTINGS
  fi
fi
