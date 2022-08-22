#!/bin/hash -f
SCRIPT_NAME=`basename $0`

# To get a list of available aervice groupings
# oci limits service list --compartment-id $OCI_TENANCY --all
# To get the limits for a specific servce (use the name from above)
# oci limits value list --compartment-id $OCI_TENANCY --all --service-name <name>
# to get the details of the specific AD in the current region
# oci iam availability-domain  list --all --compartment-id $OCID
# to get the recource limits IN AN AD in the current region
# oci limits resource-availability get --compartment-id $OCI_TENANCY --availability-domain $AD_NAME --service-name $SERVICE_NAME --limit-name $LIMIT_NAME


if [ $# -lt 4 ]
then
  echo '$SCRIPT_NAME requires arguments in the following order'
  echo 'the OCID of the compartment (or tenancy) to do a resource check on'
  echo 'The service name (e.g. compute)'
  echo 'The limit name e.g. standard-e4-core-count'
  echo 'The minimum required number of resources e.g. 3'
  echo 'It will return 0 if the available number of resources is equal to or more than than the minimum required'
  echo 'It will return 50 if the available number of resources is less than the minimum required'
  echo 'It will return 99 if the resource availability cannot be retrieved'
  echo 'With the arguments above this script will return a zero code if the available number of compute e4 cores equals or exceeds 3'
  exit 1
fi

OCID=$1
SERVICE_NAME=$2
LIMIT_NAME=$3
MINIMUM_REQUIRED=$4

AD_NAME=`oci iam availability-domain  list --all --compartment-id $OCID | jq -j '.data[0].name'`

if [ -z "$AD_NAME" ]
then
  echo "Unable to get availability domain details, cannot continue"
  exit 99
fi

AVAIL_RESOURCES=`oci limits resource-availability get --compartment-id $OCI_TENANCY --availability-domain $AD_NAME --service-name $SERVICE_NAME --limit-name $LIMIT_NAME | jq -j '.data.available'`

if [ -z "$AVAIL_RESOURCES" ]
then
  echo "Unable to get resource availability for resource $LIMIT_NAME in service $SERVICE_NAME in availability domain $AD_NAME, cannot continue"
  exit 99
fi

if [ $AVAIL_RESOURCES -lt $MINIMUM_REQUIRED ]
then 
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in availability domain $AD_NAME, unfortunately only $AVAIL_RESOURCES are available"
  exit 50
else
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in availability domain $AD_NAME, congratulations $AVAIL_RESOURCES are available"
  exit 0
fi