#!/bin/bash -f

export SETTINGS=$HOME/hk8sLabsSettings


if [ -f $SETTINGS ]
  then
    echo Loading existing settings information
    source $SETTINGS
  else 
    echo No existing settings cannot contiue
    exit 10
fi

bash vault-individual-secret-destroy.sh OCIR_HOST
bash vault-individual-secret-destroy.sh OCIR_STORAGE_NAMESPACE