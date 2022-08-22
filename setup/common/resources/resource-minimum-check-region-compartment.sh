#!/bin/hash -f
SCRIPT_NAME=`basename $0`

# To get a list of available aervice groupings
# oci limits service list --compartment-id $OCI_TENANCY --all
# To get the limits for a specific servce (use the name from above)
# oci limits value list --compartment-id $OCI_TENANCY --all --service-name <name>
# to get the recource limits IN AN AD in the current region
# oci limits resource-availability get --compartment-id $OCI_TENANCY --service-name $SERVICE_NAME --limit-name $LIMIT_NAME

if [ $# -lt 4 ]
then
  echo 'Missing arguments, this script requires arguments in the following order'
  echo 'The OCID of the compartment the resources are in'
  echo 'The service name (e.g. vcn)'
  echo 'The limit name e.g. vcn-count'
  echo 'The minimum required number of resources e.g. 1'
  echo 'It will return 0 if the available number of resources is equal to or more than than the minimum required'
  echo 'It will return 50 if the available number of resources is less than the minimum required'
  echo 'It will return 98 if the resource availability is null'
  echo 'It will return 99 if the resource availability cannot be retrieved'
  echo 'With the arguments above this script will return a zero code if the available number of vcns equals or exceeds 1'
  exit 1
fi
COMPARTMENT_OCID=$1
SERVICE_NAME=$2
LIMIT_NAME=$3
MINIMUM_REQUIRED=$4

# We've been given an COMPARTMENT_OCID, let's check if it's there, if so assume it's been configured already
COMPARTMENT_NAME=`oci iam compartment get  --compartment-id $COMPARTMENT_OCID | jq -j '.data.name'`

if [ -z $COMPARTMENT_NAME ]
then
  echo "The provided COMPARTMENT_OCID of $COMPARTMENT_OCID cant be located, please check you have provided the correct value in the first param"
  exit 99
fi

AVAIL_RESOURCES=`oci limits resource-availability get --compartment-id $COMPARTMENT_OCID --service-name "$SERVICE_NAME" --limit-name $LIMIT_NAME | jq -j '.data.available'`

if [ -z "$AVAIL_RESOURCES" ]
then
  echo "Unable to get resource availability for resource $LIMIT_NAME in service $SERVICE_NAME in region compartment $COMPARTMENT_NAME, cannot continue"
  exit 99
fi

if [ "$AVAIL_RESOURCES" = "null" ]
then
  echo "Unable to get resource availability for resource $LIMIT_NAME in service $SERVICE_NAME in region compartment $COMPARTMENT_NAME the limit is null"
  exit 98
fi

if [ $AVAIL_RESOURCES -lt $MINIMUM_REQUIRED ]
then 
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in region compartment $COMPARTMENT_NAME, unfortunately only $AVAIL_RESOURCES are available"
  exit 50
else
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in region compartment $COMPARTMENT_NAME congratulations $AVAIL_RESOURCES are available"
  exit 0
fi