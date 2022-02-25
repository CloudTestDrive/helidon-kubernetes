#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot contiue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 2
fi


REPO_NAME=cloudnative-helidon-storefront



PROJECT_NAME="$USER_INITIALS"DevOpsProject
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -r '.data.name'`

echo "This script looks for an existing project called $PROJECT_NAME in $COMPARTMENT_NAME"
echo "If it finds it it will then look for an OCI Code Repo (also known as a git repo) named $REPO_NAME"
echo "To prevent damaging any existing contents the OCI Code repo must be newly created and not have any"
echo "commits or branches"
echo "You must have manually created both of these in advance as this script will not create them for you."
echo "Assuming it finds these it will download into the OCI cloud shell the source code to be used in this lab"
echo "and will then configure your local git environment and upload the source code to the OCI Code repo"
echo "in your project."

echo "Checking environment - looking for an existing local repo"

if [ -d $HOME/$REPO_NAME ]
then
  echo "The directory $REPO_NAME already exists, to prvend unintentional damage this script will stop"
  exit 1
else
  echo "No local repo, continuing"
fi

echo "Checking environment - looking for project $PROJECT_NAME"

PROJECT_OCID=`oci devops project list --compartment-id $COMPARTMENT_OCID --all --name $PROJECT_NAME --lifecycle-state ACTIVE | jq -r '.data.items[0].id'`

if [ "$PROJECT_OCID" = "null" ]
then
  echo "Cannot locate a project called $PROJECT_NAME in $COMPARTMENT_NAME"
  echo "Have you create the project ?"
  echo "If you have not created the project then you can do so, along with the OCI Code repo and re-run this script"
  echo "If you have created the project using a different name then you will have to rename it before re-running"
  echo "this script or follow the manual processes to upload your sample code."
  exit 20
else
  echo "Located project called $PROJECT_NAME in $COMPARTMENT_NAME"
fi

echo "Checking environment - looking for OCI Code repo $REPO_NAME"

REPO_OCID=`oci devops repository list --all --lifecycle-state ACTIVE --name $REPO_NAME --project-id  $PROJECT_OCID | jq -r '.data.items[0].id'`

if [ "$REPO_OCID" = "null" ]
then
  echo "Cannot locate a OCI Code repo called $REPO_NAME in devops project $PROJECT_NAME in $COMPARTMENT_NAME"
  echo "Have you create the OCI Code Repo ?"
  echo "If you have not created the OCI code then you can do so, and re-run this script"
  echo "If you have created the OCI Code repo using a different name then you will have to rename it before re-running"
  echo "this script or follow the manual processes to upload your sample code."
  exit 21
else
  echo "Located OCI Code repo called $REPO_NAME in devops project $PROJECT_NAME in $COMPARTMENT_NAME"
fi

echo "Checking environment - ensuring that OCI Code repo $REPO_NAME had no branches"

COMMIT_COUNT=`oci devops repository get --repository-id $REPO_OCID | jq -r '.data."commit-count"'`
if [ "$COMMIT_COUNT" = "null" ]
then
  echo "No commits found, continuing"
else
  echo "OCI Code repo $REPO_NAME has $COMMIT_COUNT existing commits, cannot proceed as there may be damage to existing data"
  echo "You will have to manually configure the OCI Code repo"
fi

echo "Checking environment - ensuring that OCI Code repo $REPO_NAME had no branches"
BRANCH_COUNT=`oci devops repository get --repository-id $REPO_OCID | jq -r '.data."branch-count"'`

if [ "$BRANCH_COUNT" = "null" ]
then
  echo "No branches found, continuing"
else
  echo "OCI Code repo $REPO_NAME has $BRANCH_COUNT existing branches, cannot proceed as there may be damage to existing data"
  echo "You will have to manually configure the OCI Code repo"
fi

REPO_SSH=`oci devops repository get --repository-id $REPO_OCID | jq -r '.data."ssh-url"'`

if [ -z $REPO_SSH ]
then
  echo "Cannot get ssh access info foe OCI Code repo $REPO_NAME in devops project $PROJECT_NAME in $COMPARTMENT_NAME"
  echo "This shouldn't happen !"
  exit 22
else
  echo "Located ssh access details for OCI Code repo called $REPO_NAME in devops project $PROJECT_NAME in $COMPARTMENT_NAME"
fi

read -p "Ready to start demo project code transfer, proceed ?"
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, stopping"
  exit 0
else
  echo "OK' starting to transfer sample code"
fi


SAVED_PWD=`pwd`

cd $HOME

echo "Downloading sample code into OCI Cloud Shell"
git clone https://github.com/oracle-devrel/$REPO_NAME.git

cd $REPO_NAME

echo "Configuring git user info"
git config user.email "$USER_INITIAL@email.com"
git config user.name "$USER_INITIALS"

echo "Switching git remote repo"
git remote add devops  $REPO_SSH
git remote remove origin

echo "Updating from core OCI Code repo main branch"
git pull --no-edit --allow-unrelated-histories devops main

echo "Uploading to OCI Code repo"
git push devops main

echo "Sample code transfered"
echo "IMPORTANT this will be on the default branch, remember to create a working branch before making any code changes"

cd $SAVED_PWD