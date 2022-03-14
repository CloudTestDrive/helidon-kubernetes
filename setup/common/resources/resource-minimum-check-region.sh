#!/bin/hash -f
# To get a list of available aervice groupings
# oci limits service list --compartment-id $OCI_TENANCY --all
# To get the limits for a specific servce (use the name from above)
# oci limits value list --compartment-id $OCI_TENANCY --all --service-name <name>
# to get the recource limits IN AN AD in the current region
# oci limits resource-availability get --compartment-id $OCI_TENANCY --service-name $SERVICE_NAME --limit-name $LIMIT_NAME

if [ $# -lt 3 ]
then
  echo 'Missing arguments, this script requires arguments in the following order'
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

SERVICE_NAME=$1
LIMIT_NAME=$2
MINIMUM_REQUIRED=$3

AVAIL_RESOURCES=`oci limits resource-availability get --compartment-id $OCI_TENANCY --service-name "$SERVICE_NAME" --limit-name $LIMIT_NAME | jq -j '.data.available'`

if [ -z "$AVAIL_RESOURCES" ]
then
  echo "Unable to get resource availability for resource $LIMIT_NAME in service $SERVICE_NAME in region, cannot continue"
  exit 99
fi

if [ "$AVAIL_RESOURCES" = "null" ]
then
  echo "Unable to get resource availability for resource $LIMIT_NAME in service $SERVICE_NAME in region the limit is null"
  exit 98
fi

if [ $AVAIL_RESOURCES -lt $MINIMUM_REQUIRED ]
then 
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in region, unfortunately only $AVAIL_RESOURCES are available"
  exit 50
else
  echo "You asked for $MINIMUM_REQUIRED of resource $LIMIT_NAME in service $SERVICE_NAME in region congratulations $AVAIL_RESOURCES are available"
  exit 0
fi