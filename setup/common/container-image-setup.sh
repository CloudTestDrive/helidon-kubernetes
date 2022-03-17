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


# Get the OCIR locations
echo "Locating repo names"
OCIR_STOCKMANAGER_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOCKMANAGER_OCID | jq -r '.data."display-name"'`
OCIR_STOREFRONT_NAME=`oci artifacts  container repository get  --repository-id $OCIR_STOREFRONT_OCID | jq -r '.data."display-name"'`


echo "Checking for existing images"
IMAGE_STOCKMANAGER_V001_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOCKMANAGER_V001_OCID ]
then
  IMAGE_STOCKMANAGER_V001_OCID="null"
fi
IMAGE_STOCKMANAGER_V002_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOCKMANAGER_NAME:0.0.2 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOCKMANAGER_V002_OCID ]
then
  IMAGE_STOCKMANAGER_V002_OCID="null"
fi
IMAGE_STOREFRONT_V001_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOREFRONT_V001_OCID ]
then
  IMAGE_STOREFRONT_V001_OCID="null"
fi
IMAGE_STOREFRONT_V002_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_STOREFRONT_NAME:0.0.2 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_STOREFRONT_V002_OCID ]
then
  IMAGE_STOREFRONT_V002_OCID="null"
fi

# if we have OCID's for all of the images no need to continue
DO_BUILDS="false"
if [ "$IMAGE_STOCKMANAGER_V001_OCID" = "null" ]
then
  echo "Missing stockmanager v0.0.1 image, build required"
  DO_BUILDS="true"
else
  echo "Located image for stockmanager v0.0.1 image"
fi

if [ "$IMAGE_STOCKMANAGER_V002_OCID" = "null" ]
then
  echo "Missing stockmanager v0.0.2 image, build required"
  DO_BUILDS="true"
else
  echo "Located image for stockmanager v0.0.2 image"
fi


if [ "$IMAGE_STOREFRONT_V001_OCID" = "null" ]
then
  echo "Missing storefront v0.0.1 image, build required"
  DO_BUILDS="true"
else
  echo "Located image for storefront v0.0.1 image"
fi


if [ "$IMAGE_STOREFRONT_V002_OCID" = "null" ]
then
  echo "Missing storefront v0.0.2 image, build required"
  DO_BUILDS="true"
else
  echo "Located image for storefront v0.0.2 image"
fi

if [ "$DO_BUILDS" = "false" ]
then
  echo "Found existing images for both storefront and stockmanager v0.0.1 and v0.0.2, no point in rebuilding"
  echo "If you need to rebuild them then please destroy the existing images and re-run this script"
  exit 0
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

echo "Removing any old directories"
cd $HOME

if [ -d $WORK_DIR ]
then
  echo "Image build working directory $WORK_DIR exists, deleting"
  rm -rf $WORK_DIR
fi
if [ -e $WORK_DIR ]
then
  echo "A file named the same as the image build working directory ($WORK_DIR) exists, deleting"
  rm $WORK_DIR
fi

echo "About to install Java into $WORK_DIR from $JAVA_LOCATION"
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


echo "Building and pushing stockmanager images"

cd $WORK_DIR/"$STOCKMANAGER_GIT_NAME"

cd $STOCKMANAGER_LOCATION_IN_REPO


# update the repo location
echo "REPO=$OCIR_STOCKMANAGER_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOCKMANAGER_NAME" > repoStockmanagerConfig.sh

# build the images and push them if needed
if [ -z $"IMAGE_STOCKMANAGER_V001_OCID" ]
then
  bash buildStockmanagerPushToRepo.sh
else 
  echo "Located a Stockmanager v 0.0.1 image, reusing it"
fi

if [ -z $"IMAGE_STOCKMANAGER_V001_OCID" ]
then
  bash buildStockmanagerPushToRepo.sh
fi


if [ -z $"IMAGE_STOCKMANAGER_V002_OCID" ]
then
  bash buildStockmanagerV0.0.2PushToRepo.sh
else 
  echo "Located a Stockmanager v 0.0.2 image, reusing it"
fi

cd $SCRIPTS_DIR

bash stockmanager-deployment-update.sh set $OCIR_STOCKMANAGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOCKMANAGER_NAME


echo "Building and pushing storefront images"

cd $WORK_DIR/"$STOREFRONT_GIT_NAME"

cd $STOREFRONT_LOCATION_IN_REPO

# update the repo location
echo "REPO=$OCIR_STOREFRONT_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOREFRONT_NAME" > repoStorefrontConfig.sh

# build the images and push them
if [ -z $"IMAGE_STOREFRONT_V001_OCID" ]
then
  bash buildStorefrontPushToRepo.sh
else 
  echo "Located a Storefront v 0.0.1 image, reusing it"
fi

if [ -z $"IMAGE_STOREFRONT_V002_OCID" ]
then
  bash buildStorefrontV0.0.2PushToRepo.sh
else 
  echo "Located a Storefront v 0.0.2 image, reusing it"
fi

cd $SCRIPTS_DIR
bash storefront-deployment-update.sh set $OCIR_STOREFRONT_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

rm -rf $WORK_DIR
