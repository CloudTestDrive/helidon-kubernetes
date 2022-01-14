#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot continue
    exit 10
fi


if [ -z $OCIR_STOCKMANAGER_OCIR ]
then
  echo 'No OCIR id found for stockmanager repo have you run the ocir-setup.sh script ?'
  exit 1
fi

if [ -z $OCIR_STOREFRONT_OCIR ]
then
  echo 'No OCIR id found for storefront repo have you run the ocir-setup.sh script ?'
  exit 1
fi



WORK_DIR=$HOME/tmp-docker-workspace-delete-me
JAVA_LOCATION=https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
#JAVA_LOCATION=https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz

STOCKMANAGER_GIT_NAME=cloudnative-helidon-stockmanager
STOREFRONT_GIT_NAME=cloudnative-helidon-storefront

STOCKMANAGER_GIT_REPO=https://github.com/oracle-devrel/"$STOCKMANAGER_GIT_NAME".git
STOREFRONT_GIT_REPO=https://github.com/oracle-devrel/"$STOREFRONT_GIT_NAME".git

STOCKMANAGER_LOCATION_IN_REPO=helidon-stockmanager-full
STOREFRONT_LOCATION_IN_REPO=helidon-stockmanager-full

echo Removing any old directories
cd $HOME
mkdir -p $WORK_DIR
rm -rf $WORK_DIR

echo About to install Java into $WORK_DIR from $JAVA_LOCATION
mkdir $WORK_DIR
cd $WORK_DIR
echo Downloading JDK
wget -q $JAVA_LOCATION

echo Unpacking JDK
tar xf *tar.gz
#rm *tar.gz

export JAVA_HOME=`echo $WORK_DIR/jdk-*`
export PATH=$JAVA_HOME/bin:$PATH

echo Getting source repos from git
git clone $STOCKMANAGER_GIT_REPO
git clone $STOREFRONT_GIT_REPO

# storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`

# Get the OCIR location

OCIR_STOREFRONT_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOREFRONT_OCIR | jq -r '.data."display-name"'`

cd $WORK_DIR/"$STOREFRONT_GIT_NAME".git

echo ===================================
echo REMEMBER TO REMOVE THE GIT CHECKOUT
echo ===================================

git checkout initial-code-added

cd $STOREFRONT_LOCATION_IN_REPO


# update the repo location
echo REPO=$OCIR_STOREFRONT_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOREFRONT_NAME > repoStorefrontConfig.sh

# build the images and push them
bash buildStorefrontPushToRepo.sh
bash buildStorefrontV0.0.2PushToRepo.sh
