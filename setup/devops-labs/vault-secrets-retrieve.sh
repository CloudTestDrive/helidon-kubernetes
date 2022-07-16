#!/bin/bash -f

SAVED_DIR=`pwd`

cd ../common/vault-secrets
bash ./vault-individual-secret-retrieve.sh OCIR_HOST
bash ./vault-individual-secret-retrieve.sh OCIR_STORAGE_NAMESPACE

cd $SAVED_DIR