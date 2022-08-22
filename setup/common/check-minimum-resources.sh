#!/bin/bash -f
SCRIPT_NAME=`basename $0`


context_name=one

if [ $# -gt 0 ]
then
  context_name=$1
  echo "$SCRIPT_NAME Operating on context name $context_name"
else
  echo "$SCRIPT_NAME Using default context name of $context_name"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings"
fi

RESOURCES_AVAILABLE=true

if [ -z $COMPARTMENT_OCID ]
  then
  echo "No existing compartment information"
  echo "Checking for compartment availability"
  bash ./resources/resource-minimum-check-region.sh compartments compartment-count 1
  AVAIL_COMPARTMENTS=$?

  if [ $AVAIL_COMPARTMENTS -eq 0 ]
  then
    echo "You have enough compartments available to run this lab"
  else
    echo "Sorry, but there are no available compartment resources."
    RESOURCES_AVAILABLE=false
  fi
else
  echo "You have already configured a compartment, it will be reused"
fi

if [ -z $ATPDB_OCID ]
  then
  echo "No existing database information"
  echo "Checking for database resource availability"
  bash ./resources/resource-minimum-check-region.sh database atp-ocpu-count 1
  AVAIL_DATABASES=$?

  if [ $AVAIL_DATABASES -eq 0 ]
  then
    echo "You have enough ATP database cpus available to run this lab"
  else
    echo "Sorry, but there are no available ATP database cpu resources."
    RESOURCES_AVAILABLE=false
  fi
else
  echo "You have already configured an ATP database, it will be reused"
fi

#Do a bit of messing around to basically create a rediection on the variable and context to get a context specific varible name
# Create a name using the variable
OKE_REUSED_NAME=`bash ./settings/to-valid-name.sh OKE_REUSED_$context_name`
# Now locate the value of the variable who's name is in OKE_REUSED_NAME and save it
OKE_REUSED="${!OKE_REUSED_NAME}"
if [ -z $OKE_REUSED ]
then
  echo "No already configured OKE context $context_name, checking resource availability"
  
  echo "Checking for VCN availability for Kubernetes workers"
  bash ./resources/resource-minimum-check-region.sh vcn vcn-count 1
  AVAIL_VCN=$?

  if [ $AVAIL_VCN -eq 0 ]
  then
    echo 'You have enough Virtual CLoud Networks to create the OKE cluster'
  else
    echo "Sorry, but there are no available virtual cloud network resources available to create the Kubernetes cluster."
    RESOURCES_AVAILABLE=false
  fi

  echo "Checking for E4 or E3 processor core availability for Kubernetes workers"
  # for now to get this done quickly just hard code the checks, at some point make this config driven
  bash ./resources/resource-minimum-check-ad.sh $OCI_TENANCY "compute" "standard-e4-core-count" 3
  AVAIL_E4_CORES=$?
  bash ./resources/resource-minimum-check-ad.sh $OCI_TENANCY "compute" "standard-e3-core-ad-count" 3
  AVAIL_E3_CORES=$?
  if [ $AVAIL_E4_CORES -eq 0 ]
  then
    echo "You have enough E4 shapes to create the OKE cluster"
  elif [ $AVAIL_E3_CORES -eq 0 ]
  then
  echo "You have enough E3 shapes to create the OKE cluster"
  else
    echo "Sorry, but there are no available E3 or E4 processor resources available to create the Kubernetes cluster."
    RESOURCES_AVAILABLE=false
  fi
else
  echo "You already have an OKE cluster for context $context_name, not need to check resources"
fi

bash ./resources/resource-minimum-check-region.sh load-balancer lb-flexible-count 1
AVAIL_LB_COUNT=$?
if [ $AVAIL_LB_COUNT -eq 0 ]
then
  echo 'You have enough flexible load balancers available to setup your core cluster services'
else
  echo "Sorry, but you will a flexible Load balancer to run the core cluster services."
  echo "If you have other load balancer shapes available (e.g. a fixed bandwidth load balancer) you can adjust the"
  echo "helm commands used in the lab or the Kubernetes services setup scripts to use that instead"
  RESOURCES_AVAILABLE=false
fi
bash ./resources/resource-minimum-check-region.sh load-balancer lb-flexible-bandwidth-sum 20
AVAIL_LB_THROUGHPUT=$?
if [ $AVAIL_LB_THROUGHPUT -eq 0 ]
then
  echo 'You have enough flexible load balancer throughput available to setup your core cluster services'
else
  echo "Sorry, but you will a 20MBPS of availabpe flex Load balancer throughput to run the core cluster services."
  echo "If you have other load balancer shapes available (e.g. a fixed bandwidth load balancer) you can adjust the"
  echo "helm commands used in the lab or the Kubernetes services setup scripts to use that instead"
  RESOURCES_AVAILABLE=false
fi


if [ "$AUTO_CONFIRM" = "true" ]
then
  echo "Getting user info to check for available auth tokens"
  MAX_AUTH_TOKENS=2
  # try to locate the user type
  LOCAL_USER=`echo $OCI_CS_USER_OCID | grep '^ocid1.user' | wc -l`

  if [ $LOCAL_USER = 1 ]
  then
      USER_OCID=$OCI_CS_USER_OCID
  else
    FEDERATED_USER=`echo $OCI_CS_USER_OCID | grep '^ocid1.saml' | wc -l`
    if [ $FEDERATED_USER = 1 ]
    then
      echo "You are a federated user, getting information"
      PROVIDER_OCID=`cut -d '/' -f 1 <<< $OCI_CS_USER_OCID`
      USER_ID=`cut -d '/' -f 2 <<< $OCI_CS_USER_OCID`
      # look through all of the proders looking for one that matches
      # we only know about SAML2 though
      PROVIDER_NAME=`oci iam identity-provider list --compartment-id $OCI_TENANCY --protocol SAML2 --all | jq -j ".data[] | select (.id == \"$PROVIDER_OCID\") | .name" | tr [:upper:] [:lower:] `
      USERNAME_PROVISIONAL=$PROVIDER_NAME/$USER_ID
      USER_OCID=`oci iam user list --name $USERNAME_PROVISIONAL | jq -j '.data[0].id'`
      if [ -z $USER_OCID ]
      then
        echo "Cannot locate OCID for user named $USERNAME_PROVISIONAL"
        echo "Can't check for the auth token slot availability"
      RESOURCES_AVAILABLE=false
      fi
    else
      echo "Unknown user type for $OCI_CS_USER_OCID"
      echo "Can't check for the auth token slot availability"
      RESOURCES_AVAILABLE=false
    fi
  fi
  if [ -z "$USER_OCID" ]
  then
    echo "No USER_OCID found, cannot check"
    RESOURCES_AVAILABLE=false
  else 
    echo "Checking for available auth token spaces"
    AUTH_TOKEN_COUNT=`oci iam auth-token list --user-id $USER_OCID --all | jq -e '.data | length'`
    if [ -z $AUTH_TOKEN_COUNT ]
    then
      AUTH_TOKEN_COUNT=0
    fi
    if [ $AUTH_TOKEN_COUNT -eq $MAX_AUTH_TOKENS ]
    then
      echo "You are already at the maximum number of auth tokens, in automatic mode this script trys and create one for its use"
      echo "as there are no available spaces you will have to run the script in non auto confirm mode and reuse an auth token"
      echo "by entering the value when prompted"
      RESOURCES_AVAILABLE=false
    else
      echo "You have $AUTH_TOKEN_COUNT tokens in use out of a maximum of $MAX_AUTH_TOKENS"
    fi
  fi
fi

if [ $RESOURCES_AVAILABLE ]
then
  echo "Congratulations, you have either got an existing compartment and / or OKE cluster created from other labs, or"
  echo "if not based on current resource availability (which if other people are using this tenancy"
  echo "may of course change before the OKE cluster is created) there are sufficient resources to do this lab"
  exit 0
else
  echo "You do not have the resources available to run this lab."
  echo "THIS IS NOT A DISASTER, please read the following"
  echo "If the missing resource is a load balancer AND YOU HAVE ALREADY SETUP YOUR INGRESS CONTROLLER"
  echo "Then that will be re-used, and you need not worry"
  echo "In some cases you may have existing compartments or Kubernetes clusters that you have already created that"
  echo "You can re-use, perhaps you have done the Helidon lab or one of the other Kubernetes related labs"
  echo "In that case you can just re-use them"
  echo "If you are in a free trial account in the 30 day trial period check to see if there are existing"
  echo "processor or VCN resources that you can free up."
  echo "If you are in a free trial which has changed to a always free tenancy this is to be expected as"
  echo "The always free trials to not currently have the ability to run OKE clusters"
  echo "If you are in a non free trial maybe switch to a different region (in which case you will"
  echo "have to setup the auth tokens manually) or raise a service request to increase the resource limits"
  exit 50
fi