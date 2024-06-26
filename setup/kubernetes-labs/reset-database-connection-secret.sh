#!/bin/bash
SCRIPT_NAME=`basename $0`
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


DB_CONNECTION_SECRET_DIR=$HOME/helidon-kubernetes/configurations/stockmanagerconf
DB_CONNECTION_SECRET_YAML=$DB_CONNECTION_SECRET_DIR/databaseConnectionSecret.yaml
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, Remove the configured the database connection config in $DB_CONNECTION_SECRET_YAML defaults to $REPLY"
else
  echo "Remove the configured the database connection config in $DB_CONNECTION_SECRET_YAML ."
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
fi
if [ -f "$DB_CONNECTION_SECRET_YAML" ]
then
    echo "Removing the configured the stockmanager config in $DB_CONNECTION_SECRET_YAML"
    rm $DB_CONNECTION_SECRET_YAML
else
    echo "database connection config in $DB_CONNECTION_SECRET_YAML already removed"
fi