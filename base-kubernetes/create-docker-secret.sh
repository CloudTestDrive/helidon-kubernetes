#!/bin/bash
echo Deleting existing docker secret
echo my-docker-reg
kubectl delete secret my-docker-reg --ignore-not-found=true
echo Creating docker secrets
echo my-docker-reg
kubectl create secret docker-registry my-docker-reg --docker-server=fra.ocir.io --docker-username='tenancy-name/oracleidentitycloudservice/username' --docker-password='abcdefrghijklmnopqrstuvwxyz' --docker-email='you@email.com'


