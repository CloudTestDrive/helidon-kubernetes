#!/bin/bash
read -p "Have you downloaded the DB wallet, updated the database connection, and updated the stockmager-config.yaml with the name of your store ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, please make sure you have got the DB wallet, updated the db connection settings with the connection name and updated the stockmanager-config.yaml with the name of your store"
    exit 1
fi
read -p "Have you created the ingress controller and got its external IP address ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, please create the ingress service and get the external IP address"
    exit 1
fi
read -p "Have you created the root CA and tls certificate files (tls-store.crt and tls-store.key) using the external IP address in the common name? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo OK, existing, if needed please use the create-cert.sh script to setup the tls secret
    exit 1
fi
read -p "Have you edited the ingressConfig.yaml to replace the external IP address ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo 'OK, edit ingressConfig.yaml replacing <External IP> with the IP address of the ingress service (there are multple entries excluding the comments)'
    exit 1
fi
echo Please check the output to make sure that the right context is selected as the default below
kubectl config get-contexts
read -p "Is the right cluster selected ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo OK, exiting
    exit 1
fi
read -p "Ready to delete any existing namespace $1 and setup the new stack ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo OK, exiting
    exit 1
fi
./create-namespace.sh $1
echo Creating tls secret from tls.key and tls.crt
kubectl create secret tls tls-store --key tls-store.key --cert tls-store.crt
./setupClusterIPServices.sh
./setupIngress.sh
./create-secrets.sh
./create-configmaps.sh
cd ..
./deploy.sh
