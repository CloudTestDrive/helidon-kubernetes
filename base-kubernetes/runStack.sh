#!/bin/bash
./setupClusterIPServices.sh
./setupIngress.sh
./create-secrets.sh
./create-configmaps.sh
cd ..
./deploy.sh
