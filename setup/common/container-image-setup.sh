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


if [ -z $OCIR_STOCKMANAGER_OCID ]
then
  echo 'No OCIR id found for stockmanager repo have you run the ocir-setup.sh script ?'
  exit 1
fi

if [ -z $OCIR_STOREFRONT_OCID ]
then
  echo 'No OCIR id found for storefront repo have you run the ocir-setup.sh script ?'
  exit 1
fi

SCRIPTS_DIR=`pwd`


WORK_DIR=$HOME/tmp-docker-workspace-delete-me
JAVA_LOCATION=https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
# Old version of Java
#JAVA_LOCATION=https://download.java.net/openjdk/jdk11/ri/openjdk-11+28_linux-x64_bin.tar.gz

STOCKMANAGER_GIT_NAME=cloudnative-helidon-stockmanager
STOREFRONT_GIT_NAME=cloudnative-helidon-storefront

STOCKMANAGER_GIT_REPO=https://github.com/oracle-devrel/"$STOCKMANAGER_GIT_NAME".git
STOREFRONT_GIT_REPO=https://github.com/oracle-devrel/"$STOREFRONT_GIT_NAME".git

STOCKMANAGER_LOCATION_IN_REPO=helidon-stockmanager-full
STOREFRONT_LOCATION_IN_REPO=helidon-storefront-full

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
rm *tar.gz

export JAVA_HOME=`echo -n $WORK_DIR/jdk-*`
export PATH=$JAVA_HOME/bin:$PATH

echo Maven and Java info
mvn -version

echo Getting source repos from git
git clone $STOCKMANAGER_GIT_REPO
git clone $STOREFRONT_GIT_REPO

# storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`


echo building and pushing stockmanager images

# Get the OCIR location

OCIR_STOCKMANAGER_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOCKMANAGER_OCID | jq -r '.data."display-name"'`

cd $WORK_DIR/"$STOCKMANAGER_GIT_NAME"

cd $STOCKMANAGER_LOCATION_IN_REPO


# update the repo location
echo REPO=$OCIR_STOCKMANAGER_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOCKMANAGER_NAME > repoStockmanagerConfig.sh

# build the images and push them
bash buildStockmanagerPushToRepo.sh
bash buildStockmanagerV0.0.2PushToRepo.sh

cd $SCRIPTS_DIR

bash stockmanager-deployment-update.sh set $OCIR_STOCKMANAGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOCKMANAGER_NAME


echo building and pushing storefront images

# Get the OCIR location

OCIR_STOREFRONT_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOREFRONT_OCID | jq -r '.data."display-name"'`

cd $WORK_DIR/"$STOREFRONT_GIT_NAME"

cd $STOREFRONT_LOCATION_IN_REPO


# update the repo location
echo REPO=$OCIR_STOREFRONT_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOREFRONT_NAME > repoStorefrontConfig.sh

# build the images and push them
bash buildStorefrontPushToRepo.sh
bash buildStorefrontV0.0.2PushToRepo.sh

cd $SCRIPTS_DIR
bash storefront-deployment-update.sh set $OCIR_STOREFRONT_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

rm -rf $WORK_DIR
