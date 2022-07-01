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

if [ -z "$OPENSEARCH_POLICIES_CONFIGURED" ]
then
  echo "OpenSearch policies not configured"
  exit 0
else
  echo "Removing configured OpenSearch policies"
fi

cd ../common/policies

bash ./policy-destroy.sh "$USER_INITIALS"OpenSearchVNICPolicy
bash ./policy-destroy.sh "$USER_INITIALS"OpenSearchSubnetsPolicy
bash ./policy-destroy.sh "$USER_INITIALS"OpenSearchNSGPolicy
bash ./policy-destroy.sh "$USER_INITIALS"OpenSearchSVCNSPolicy


# delete script is in common, we are in common/policies
bash ../delete-from-saved-settings.sh OPENSEARCH_POLICIES_CONFIGURED