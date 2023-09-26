#!/bin/bash -f

SCRIPT_NAME=`basename $0`
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
then
  echo "$SCRIPT_NAME Loading existing settings"
  source $SETTINGS
else 
  echo "$SCRIPT_NAME No existing settings"
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

INFO_FILE=$HOME/clusterInfo.$CLUSTER_CONTEXT_NAME

VERRAZZANO_INSTALLED_VAR="VERRAZZANO_INSTALLED_IN_CLUSTER_""$CLUSTER_CONTEXT_NAME"
if [ -z "${!VERRAZZANO_INSTALLED_VAR}" ]
then
  echo "No record of installing verrazzano in cluster $CLUSTER_CONTEXT_NAME proceeding"
else
  echo "It seems that verrazzano is already installed in cluster $CLUSTER_CONTEXT_NAME skipping"
  exit 0
fi

if [ -z "$VERRAZZANO_VERSION" ]
then
  echo "VERRAZZANO_VERSION is not set, cannot proceed"
  exit 2
else 
  echo "Proceeding with verrazzano version $VERRAZZANO_VERSION"
fi

if [ -z "$VZ_PROFILE" ]
then
  VZ_PROFILE=dev
  echo "VZ_PROFILE was not set, defaulting to $VZ_PROFILE"
else
  echo "VZ_PROFILE was to $VZ_PROFILE"
fi

SAVED_PWD=`pwd`

VERRAZZANO_DIR=$HOME/verrazzano

if [ -d "$VERRAZZANO_DIR" ]
then
  echo 
  read -p "$VERRAZZANO_DIR already exists, we need a fresh directory, do you want to remove it (y/n) ?" REPLY
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "OK, you will have to move this directory to a new location and run this script again"
    exit 1
  else 
    rm -rf "$VERRAZZANO_DIR"
  fi
else
  echo "$VERRAZZANO_DIR does not exist, creating it"
fi
mkdir -p $VERRAZZANO_DIR

cd $VERRAZZANO_DIR
VERRAZZANO_BASE="verrazzano-""$VERRAZZANO_VERSION"
VERRAZANO_DOWNLOAD_BASE_FILE="$VERRAZZANO_BASE""-linux-amd64.tar.gz"
VERRAZANO_DOWNLOAD_CHECKSUM_FILE="$VERRAZANO_DOWNLOAD_BASE_FILE"".sha256"
VERRAZANO_DOWNLOAD_BASE_URL="https://github.com/verrazzano/verrazzano/releases/download/v""$VERRAZZANO_VERSION""/"
VERRAZZANO_DOWNLOAD_URL_FILE="$VERRAZANO_DOWNLOAD_BASE_URL""$VERRAZANO_DOWNLOAD_BASE_FILE"
VERRAZZANO_DOWNLOAD_URL_CHECKSUM="$VERRAZANO_DOWNLOAD_BASE_URL""$VERRAZANO_DOWNLOAD_CHECKSUM_FILE"

echo "Downloading Verrazzano installer from $VERRAZZANO_DOWNLOAD_URL_FILE"
curl -LO "$VERRAZZANO_DOWNLOAD_URL_FILE"

echo "Downloading Verrazzano installer checksum from $VERRAZZANO_DOWNLOAD_URL_CHECKSUM"
curl -LO "$VERRAZZANO_DOWNLOAD_URL_CHECKSUM"

echo "Comparimg checksums using checksum file $VERRAZANO_DOWNLOAD_CHECKSUM_FILE"
CHECKSUM_OUTPUT=`sha256sum -c $VERRAZANO_DOWNLOAD_CHECKSUM_FILE`
OK_CHECKSUM=`echo $CHECKSUM_OUTPUT | grep OK | wc -l`
if [ "$OK_CHECKSUM" -ge 1 ]
then
  echo "Checksums matched, continuing"
else
  echo "Downloaded checksums didn't match cannot continue"
  echo "checksum message is $CHECKSUM_OUTPUT"
  exit 3
fi

echo "Unpacking $VERRAZANO_DOWNLOAD_BASE_FILE"
tar xvf $VERRAZANO_DOWNLOAD_BASE_FILE
VERRAZZANO_INSTALL_DIR=$VERRAZZANO_DIR/$VERRAZZANO_BASE
echo "Verrazzano installed to $VERRAZZANO_INSTALL_DIR"
cd "$VERRAZZANO_INSTALL_DIR/bin"

echo "Checking version"
VERSION_OUTPUT=`./vz version`
OK_VERSION=`echo $CHECKSUM_OUTPUT | grep $VERRAZZANO_VERSION | wc -l`
if [ "$OK_CHECKSUM" -gt 0 ]
then
  echo "Version is $VERRAZZANO_VERSION, continuing"
else
  echo "Downloaded version is not $VERRAZZANO_VERSION as expected, cannot continue"
  echo "Version message is $VERSION_OUTPUT"
  exit 4
fi

echo "Installing verrazzano, this will take a while, it can take upto 30 mins"
./vz install -f - <<EOF
apiVersion: install.verrazzano.io/v1beta1
kind: Verrazzano
metadata:
  name: example-verrazzano
spec:
  profile: dev
EOF

echo "Verrazzano servcies url's"
kubectl get vz -o jsonpath="{.items[].status.instance}" --context $CLUSTER_CONTEXT_NAME | jq . 
echo "Verrazzano services url's" >> $INFO_FILE
kubectl get vz -o jsonpath="{.items[].status.instance}" --context $CLUSTER_CONTEXT_NAME | jq . >> $INFO_FILE

VERRAZZANO_PASSWORD=`kubectl get secret     --namespace verrazzano-system verrazzano     -o jsonpath={.data.password} --context $CLUSTER_CONTEXT_NAME | base64     --decode; echo`

echo "Verrazzano user is : verrazzano"
echo "Verrazzano password is : $VERRAZZANO_PASSWORD"
echo "Verrazzano user is : verrazzano" >> $INFO_FILE 
echo "Verrazzano password is : $VERRAZZANO_PASSWORD">> $INFO_FILE 

KEYCLOAK_PASSWORD=`kubectl get secret  --namespace keycloak keycloak-http  -o jsonpath={.data.password} --context $CLUSTER_CONTEXT_NAME | base64     --decode; echo`

echo "Keycloak user is : keycloakadmin"
echo "Keycloak password is : $KEYCLOAK_PASSWORD"
echo "Keycloak user is : keycloakadmin">> $INFO_FILE
echo "Keycloak password is : $KEYCLOAK_PASSWORD">> $INFO_FILE



RANCHER_PASSWORD=`kubectl get secret  --namespace cattle-system rancher-admin-secret  -o jsonpath={.data.password} --context $CLUSTER_CONTEXT_NAME | base64     --decode; echo`

echo "Rancher user is : admin"
echo "Rancher password is : $RANCHER_PASSWORD"
echo "Rancher user is : admin">> $INFO_FILE
echo "Rancher password is : $RANCHER_PASSWORD">> $INFO_FILE

echo "$VERRAZZANO_INSTALLED_VAR=true" >> $SETTINGS

