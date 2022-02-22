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

source $SETTINGS

if [ -z $COMPARTMENT_OCID ]
then
  echo Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script
  exit 2
fi

cd ../common/dynamic-groups

bash ./dynamic-group-setup.sh "$USER_INITIALS"BuildDynamicGroup devopsbuildpipeline "This dynamic group identifies the DevOps Build Pipelines"
bash ./dynamic-group-setup.sh "$USER_INITIALS"CodeReposDynamicGroup devopsrepository "This dynamic group identifies the OCI code repositories resources"
bash ./dynamic-group-setup.sh "$USER_INITIALS"DeployDynamicGroup devopsdeploypipeline "This dynamic group identifies the deployment tools resources"