#!/bin/bashSCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide :"
    echo "  1st arg the name of your department - in lower case and only a-z, e.g. tg"
    echo "Optional"
    echo "  2nd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
DEPARTMENT=$1
if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi


if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on supplied context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

SCRIPT_NAME=`basename $0`
if [ $# -eq 0 ]
  then
    echo "$SCRIPT_NAME No arguments supplied, you must provide the \"_high\" name of your database - e.g. tgdemo_high"
    exit -1 
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
DB_CONNECTION_NAME=$1
export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings"
    source $SETTINGS
  else 
    echo "No existing settings, cannot continue"
    exit 10
fi

if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection defaults to $REPLY"
else
  echo "Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Updating the database connection secret config to set $DB_CONNECTION_NAME as the database connection"
fi
DB_CONNECTION_SECRET_DIR=$HOME/helidon-kubernetes/configurations/stockmanagerconf
DB_CONNECTION_SECRET_YAML_TEMPLATE=$DB_CONNECTION_SECRET_DIR/databaseConnectionSecret-template.yaml
DB_CONNECTION_SECRET_YAML=$DB_CONNECTION_SECRET_DIR/databaseConnectionSecret.yaml
TEMP="$DB_CONNECTION_SECRET_YAML".tmp
echo "Updating the database connection secret config in $DB_CONNECTION_SECRET_YAML to set $DB_CONNECTION_NAME as the database connection"
# echo command is "s/<database connection name>/$DB_CONNECTION_NAME/"
cat $DB_CONNECTION_SECRET_YAML_TEMPLATE | sed -e "s/<database connection name>/$DB_CONNECTION_NAME/" > $TEMP
if [ -f "$DB_CONNECTION_SECRET_YAML" ]
then
   echo "Removing old $DB_CONNECTION_SECRET_YAML file"
   rm $DB_CONNECTION_SECRET_YAML
else
   echo "No old DB_CONNECTION_SECRET_YAML file to remove" 
fi
mv $TEMP $DB_CONNECTION_SECRET_YAML