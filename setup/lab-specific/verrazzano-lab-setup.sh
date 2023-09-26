#!/bin/bash -f
if [ -f ./script-locations.sh ]
then
  source ./script-locations.sh
else
  echo "Unable to locate the script-locations.sh file, are you running in the right directory ?"
  exit -1
fi
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=verrazzano
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi

echo "This script will setup the verrazano configuration in cluster $CLUSTER_CONTEXT_NAME"

read -p "Do you want to do the full OKE setup including services (y) otherwise it will just install the core (cluster, compartment, images and db) (y/n) " REPLY
if [[ ! $REPLY =~ ^[Yy]$ ]]
then  
  echo "OK, will just install the core services"
  SERVICES_TYPE="core services (compartment, db, images and OKE cluster) only"
  SCRIPT_NAME=core-kubernetes-lab-setup.sh
else    
  echo "OK, will just install the core services and the microservices"
  SERVICES_TYPE="core (compartment, db, images and OKE cluster) and microservices (zipkin, storefront, stockmanager, ingress controller, dashboard)"
  SCRIPT_NAME=optional-kubernetes-lab-setup.sh
fi
echo "This script used the kubernetes labs setup scripts to install $SERVICES_TYPE , you will need to respond to it's prompts"
bash ./$SCRIPT_NAME $CLUSTER_CONTEXT_NAME
echo "Now the $SERVICES_TYPE lab setup has completed starting verrazzano core setup"
SAVED_PWD=`pwd`

cd $MODULES_DIR
bash ./verrazzano-setup.sh $CLUSTER_CONTEXT_NAME