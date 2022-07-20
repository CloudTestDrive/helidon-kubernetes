#!/bin/bash -f
SCRIPT_NAME=`basename $0`
if [ $# -lt 3 ]
  then
    echo "Missing arguments supplied to $SCRIPT_NAME, you must provide :"
    echo " 1st arg the directory to process"
    echo " 2nd arg origional text"
    echo " 3rd arg replacement text"
    echo "Optional"
    echo "  4th arg the name of the kubeconfig context - defaults to one"
    exit -1 
fi
INGRESS_DIR=$1
OLD_TEXT=$2
NEW_TEXT=$3

CLUSTER_CONTEXT_NAME=one
if [ $# -ge 4 ]
then
  CLUSTER_CONTEXT_NAME=$4
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME  Using default context name of $CLUSTER_CONTEXT_NAME"
fi
for INGRESS_TEMPLATE_FILE in $INGRESS_DIR/ingress*Rules.yaml 
do
   DEST_FILE=`echo $INGRESS_TEMPLATE_FILE | sed -e "s/Rules/Rules-$CLUSTER_CONTEXT_NAME/"`
   echo "Templating $INGRESS_TEMPLATE_FILE  to $destfile"
   bash $HOME/helidon-kubernetes/setup/common/template-file.sh $INGRESS_TEMPLATE_FILE $DEST_FILE $OLD_TEXT.nip.io $NEW_TEXT.nip.io
done