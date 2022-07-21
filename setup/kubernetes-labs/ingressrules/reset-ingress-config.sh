#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -lt 1 ]
  then
    echo "Missing arguments supplied to $SCRIPT_NAME, arguments required: "
    echo " 1st arg You must provide the directory to process"
    echo "Optional args"
    echo " 2nd arg cluster context namme this relates to - defaults to one if not provided"
    exit -1 
fi

INGRESS_DIR=$1

CLUSTER_CONTEXT_NAME=one
if [ $# -ge 2 ]
then
  CLUSTER_CONTEXT_NAME=$2
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME  Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm set - Removing the ingress rules yaml for context $CLUSTER_CONTEXT_NAME in $INGRESS_DIR defaulting to $REPLY"
else
  echo "Removing the ingress rules yaml for context $CLUSTER_CONTEXT_NAME in $INGRESS_DIR"
  read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "OK, about to remove the customised ingress rules"
else
   echo "OK, exiting"
   exit 1
fi

echo "Removing the ingress rules yaml for context $CLUSTER_CONTEXT_NAME in $INGRESS_DIR"
for INGRESS_RULES_FILE in $ingressdir/ingress*Rules-$CLUSTER_CONTEXT_NAME.yaml 
do
  echo "Removing ingress rules yaml $INGRESS_RULES_FILE"
  rm $INGRESS_RULES_FILE
done
