#!/bin/bash
SCRIPT_NAME=`basename $0`
if [ $# -lt 2 ]
  then
    echo "Missing arguments supplied to $SCRIPT_NAME, you must provide :"
    echo " 1st arg the directory to process"
    echo " 2nd arg External IP address of the ingress controler service"
    echo "Optional"
    echo "  3rd arg the name of the kubeconfiug context"
    exit -1 
fi
INGRESS_DIR=$1
EXTERNAL_IP=$2
CLUSTER_CONTEXT_NAME=one
if [ $# -ge 3 ]
then
  CLUSTER_CONTEXT_NAME=$3
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
  echo "Auto confirm enabled, Templating the ingress rules yaml in $INGRESS_DIR to set $EXTERNAL_IP as the External IP address defaulting to $REPLY."
else
  echo "Templating the ingress rules yaml in $INGRESS_DIR to set $EXTERNAL_IP as the External IP address."
  read -p "Proceed (y/n) ?"  REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, Won't template the ingress rules"
  exit 1
else
  echo "Templating the ingress rules"
fi
echo "Templating ingress rules - updating the template ingress rules yaml in $INGRESS_DIR setting $EXTERNAL_IP as the external IP address"
bash $HOME/helidon-kubernetes/setup/kubernetes-labs/ingressrules/template-ingress.sh  $INGRESS_DIR '${EXTERNAL_IP}' $EXTERNAL_IP $CLUSTER_CONTEXT_NAME