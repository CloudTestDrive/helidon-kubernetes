#!/bin/bash -f

CURRENT_LOCATION=`pwd`
SCRIPT_NAME=`basename $0`

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME  No existing settings cannot continue"
    exit 10
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi


if [ -z $OCIR_BASE_NAME ]
then
  echo 'No base name found,  have you run the ocir-setup.sh script ?'
  exit 1
fi

# Get the OCIR locations
echo "Locating repo names"

OCIR_STOCKMANAGER_NAME=$OCIR_BASE_NAME/stockmanager
OCIR_LOGGER_NAME=$OCIR_BASE_NAME/logger
OCIR_STOREFRONT_NAME=$OCIR_BASE_NAME/storefront

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

IMAGE_LOGGER_V001_OCID=`oci artifacts container image list --compartment-id $COMPARTMENT_OCID --display-name $OCIR_LOGGER_NAME:0.0.1 | jq -j ".data.items[0].id"`
if [ -z $IMAGE_LOGGER_V001_OCID ]
then
  IMAGE_LOGGER_V001_OCID="null"
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

if [ "$IMAGE_LOGGER_V001_OCID" = "null" ]
then
  echo "Missing logger v0.0.1 image, build required"
  DO_BUILDS="true"
else
  echo "Located image for logger v0.0.1 image"
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
  echo "Found existing images for storefront and stockmanager v0.0.1 and v0.0.2 and logger v0.0.1, no point in rebuilding"
  echo "If you need to rebuild them then please destroy the existing images and re-run this script"
  exit 0
fi
SCRIPTS_DIR=`pwd`


WORK_DIR=$HOME/tmp-docker-workspace-delete-me


# define the jdk version we want
if [ -z "$JAVA_VERSION_FOR_BUILD" ]
then
  export JAVA_VERSION_FOR_BUILD=17
fi

# some versions of the clud shell have been switched from x68 to arm, so we need to get the right version
# of the java compile stuff
# get the system type
ARCH_NAME=`uname -m`
if [ "$ARCH_NAME" == "x86_64" ]
then
	JAVA_DOWNLOAD_ARCH="x64"
elif [ "$ARCH_NAME" == "aarch64" ]
then
	JAVA_DOWNLOAD_ARCH="aarch64"
else 
	echo "Unknown system architecture $ARCH_NAME don't know what version of java top download and cannot continue with image build"
	exit 10
fi
echo "Downloading java arch version $JAVA_DOWNLOAD_ARCH"
# this version is probabaly broken as the "latest" isn't available anymore
#JAVA_LOCATION="https://download.oracle.com/java/$JAVA_VERSION_FOR_BUILD/latest/jdk-""$JAVA_VERSION_FOR_BUILD""_linux-""$JAVA_DOWNLOAD_ARCH""_bin.tar.gz"
# for now it's more hard coded
JAVA_LOCATION="https://download.oracle.com/java/17/archive/jdk-17.0.12_linux-""$JAVA_DOWNLOAD_ARCH""_bin.tar.gz"


DEV_REL_GITHUB=https://github.com/oracle-devrel

STOCKMANAGER_GIT_NAME=cloudnative-helidon-stockmanager
LOGGER_GIT_NAME=cloudnative-helidon-logger
STOREFRONT_GIT_NAME=cloudnative-helidon-storefront

STOCKMANAGER_GIT_REPO="$DEV_REL_GITHUB"/"$STOCKMANAGER_GIT_NAME".git
LOGGER_GIT_REPO="$DEV_REL_GITHUB"/"$LOGGER_GIT_NAME".git
STOREFRONT_GIT_REPO="$DEV_REL_GITHUB"/"$STOREFRONT_GIT_NAME".git

STOCKMANAGER_LOCATION_IN_REPO=helidon-stockmanager-full
LOGGER_LOCATION_IN_REPO=helidon-logger
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
mkdir -p $WORK_DIR
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
git clone $LOGGER_GIT_REPO
git clone $STOREFRONT_GIT_REPO

# storage namespace
OBJECT_STORAGE_NAMESPACE=`oci os ns get | jq -j '.data'`


echo "Building and pushing stockmanager images"

cd $WORK_DIR/"$STOCKMANAGER_GIT_NAME"

cd $STOCKMANAGER_LOCATION_IN_REPO
if [ "$IMAGE_STOCKMANAGER_V001_OCID" = "null" ] ||  [ "$IMAGE_STOCKMANAGER_V002_OCID" = "null" ]
then
  bash $CURRENT_LOCATION/switch-git-branch.sh
fi

# update the repo location
echo "REPO=$OCIR_STOCKMANAGER_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOCKMANAGER_NAME" > repoStockmanagerConfig.sh

# build the images and push them if needed
if [ "$IMAGE_STOCKMANAGER_V001_OCID" = "null" ]
then
  bash buildStockmanagerPushToRepo.sh
else 
  echo "Located a Stockmanager v 0.0.1 image, reusing it"
fi


if [ "$IMAGE_STOCKMANAGER_V002_OCID" = "null" ]
then
  bash buildStockmanagerV0.0.2PushToRepo.sh
else 
  echo "Located a Stockmanager v 0.0.2 image, reusing it"
fi

cd $SCRIPTS_DIR

bash stockmanager-deployment-update.sh set $OCIR_STOCKMANAGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOCKMANAGER_NAME

echo "Building and pushing logger images"

cd $WORK_DIR/"$LOGGER_GIT_NAME"

cd $LOGGER_LOCATION_IN_REPO


if [ "$IMAGE_LOGGER_V001_OCID" = "null" ]
then
  bash $CURRENT_LOCATION/switch-git-branch.sh
fi
# update the repo location
echo "REPO=$OCIR_LOGGER_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_LOGGER_NAME" > repoLoggerConfig.sh

# build the images and push them if needed
if [ "$IMAGE_LOGGER_V001_OCID" = "null" ]
then
  bash buildLoggerPushToRepo.sh
else 
  echo "Located a Logger v 0.0.1 image, reusing it"
fi


cd $SCRIPTS_DIR

bash logger-deployment-update.sh set $OCIR_LOGGER_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_LOGGER_NAME

echo "Building and pushing storefront images"

cd $WORK_DIR/"$STOREFRONT_GIT_NAME"

cd $STOREFRONT_LOCATION_IN_REPO

if [ "$IMAGE_STOREFRONT_V001_OCID" = "null" ] ||  [ "$IMAGE_STOREFRONT_V002_OCID" = "null" ]
then
  bash $CURRENT_LOCATION/switch-git-branch.sh
fi

# update the repo location
echo "REPO=$OCIR_STOREFRONT_LOCATION/$OBJECT_STORAGE_NAMESPACE/$OCIR_STOREFRONT_NAME" > repoStorefrontConfig.sh

# build the images and push them
if [ "$IMAGE_STOREFRONT_V001_OCID" = "null" ]
then
  bash buildStorefrontPushToRepo.sh
else 
  echo "Located a Storefront v 0.0.1 image, reusing it"
fi

if [ "$IMAGE_STOREFRONT_V002_OCID" = "null" ]
then
  bash buildStorefrontV0.0.2PushToRepo.sh
else 
  echo "Located a Storefront v 0.0.2 image, reusing it"
fi

cd $SCRIPTS_DIR
bash storefront-deployment-update.sh set $OCIR_STOREFRONT_LOCATION $OBJECT_STORAGE_NAMESPACE $OCIR_STOREFRONT_NAME

if [ -z "$RETAIN_IMAGE_WORK_DIR" ]
then
  echo "Destroying temp image working space $WORK_DIR"
  rm -rf $WORK_DIR
else 
  echo "Retaining the image repo $WORK_DIR"
fi

cd $SCRIPTS_DIR
if [ "$SIGN_OCIR_IMAGES" = "true" ]
then
  bash ./container-image-sign.sh $OCIR_BASE_NAME
fi