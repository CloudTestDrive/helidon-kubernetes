#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -ne 2 ]
  then
    echo "$SCRIPT_NAME Missing arguments, you must provide :"
    echo "  1st arg the name of the namespace to use"
    echo "  2nd arg External IP address of the ingress controller service"
    echo "Optional"
    echo "  3rd arg the name of your cluster context (if not provided one will be used by default)"
    exit -1 
fi
NAMESPACE=$1
EXTERNAL_IP=$2

if [ -z "$DEFAULT_CLUSTER_CONTEXT_NAME" ]
then
  CLUSTER_CONTEXT_NAME=one
else
  CLUSTER_CONTEXT_NAME="$DEFAULT_CLUSTER_CONTEXT_NAME"
fi
if [ $# -ge 3 ]
then
  CLUSTER_CONTEXT_NAME=$3
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
read -p "Have you downloaded the DB wallet, updated the database connection, and updated the stockmager-config.yaml with the name of your store (y/n) ? " 
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, please make sure you have got the DB wallet, updated the db connection settings with the connection name and updated the stockmanager-config.yaml with the name of your store"
    exit 1
fi
read -p "Have you created the root CA  (y/n) ?" 
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, exiting, please create the root CA"
    exit 1
fi

read -p "You are sure you want to use cluster context $CLUSTER_CONTEXT_NAME (y/n) ?" 
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, exiting"
    exit 1
fi
read -p "Ready to delete any existing namespace $NAMESPACE and setup the new stack using ingress controller load balancer $EXTERNAL_IP in cluster context $CLUSTER_CONTEXT_NAME as the external IP (y/n) ?" 
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, exiting"
    exit 1
fi

bash ./executeRunStack.sh $NAMESPACE $EXTERNAL_IP $CLUSTER_CONTEXT_NAME