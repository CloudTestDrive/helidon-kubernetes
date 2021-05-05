#!/bin/bash
echo You must have setup the tls secret and ingress controller before running this script
read -p "Ready to procees with namespace $1 ? " -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo OK, existing, if needed please use the create-cert.sh script to setup the tls secret and install the ingress controller using Helm
    exit 1
fi
./setupClusterIPServices.sh
./setupIngress.sh
./create-secrets.sh
./create-configmaps.sh
cd ..
./deploy.sh
