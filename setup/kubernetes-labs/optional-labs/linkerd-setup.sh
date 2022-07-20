#!/bin/bash -f
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "$SCRIPT_NAME Loading existing settings information"
    source $SETTINGS
  else 
    echo "$SCRIPT_NAME No existing settings cannot continue"
    exit 10
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

source $HOME/clusterSettings.$CLUSTER_CONTEXT_NAME

echo "Checking for existing linkerd installation directory"
if [ -d $HOME/.linkerd2 ]
then
  echo "Found existing $HOME/.linkerd2 removing"
  rm -rf $HOME/.linkerd2
else
  echo "No existing linkerd, progressing the install"
fi

echo "Downloading linkerd"
curl -sL https://run.linkerd.io/install | sh

echo "Updating path for script"
export PATH=$PATH:$HOME/.linkerd2/bin
echo "To make this permenant you'll need to edit your .bashrc and add the following line"
echo 'export PATH=$PATH:$HOME/.linkerd2/bin'


echo "Installing linkerd into cluster $CLUSTER_CONTEXT_NAME"
linkerd install --context $CLUSTER_CONTEXT_NAME | kubectl apply --context $CLUSTER_CONTEXT_NAME -f -

echo "Running post install check to ensure linkerd core is installed in cluster $CLUSTER_CONTEXT_NAME"
linkerd check --context $CLUSTER_CONTEXT_NAME

echo "Installing linkerd visual tools"
linkerd viz install --context $CLUSTER_CONTEXT_NAME | kubectl apply--context $CLUSTER_CONTEXT_NAME  -f -

echo "Running post install check to ensure linkerd core is installed in cluster $CLUSTER_CONTEXT_NAME"
linkerd check --context $CLUSTER_CONTEXT_NAME

echo "Remember to edit the linkerd visuals deployment and clean out the enforced-hotst element"
echo " Use 'kubectl edit deployment web -n linkerd-viz'"

cd $HOME/helidon-kubernetes/service-mesh

echo "Create linkerd visuals certificates"
cd $HOME/helidon-kubernetes/service-mesh
$HOME/keys/step certificate create linkerd.$EXTERNAL_IP.nip.io tls-linkerd-$EXTERNAL_IP.crt tls-linkerd-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Create linkerd visuals secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret tls tls-linkerd --key tls-linkerd-$EXTERNAL_IP.key --cert tls-linkerd-$EXTERNAL_IP.crt -n linkerd-viz --context $CLUSTER_CONTEXT_NAME

USERNAME=admin
PASSWORD=ZaphodBeeblebrox
echo "Setting linkerd UI password to $PASSWORD"
htpasswd -c -b auth $USERNAME $PASSWORD

echo "Creating linkerd UI password secret in cluster $CLUSTER_CONTEXT_NAME"
kubectl create secret generic web-ingress-auth -n linkerd-viz --from-file=auth --context $CLUSTER_CONTEXT_NAME

echo "Configuring linkerd ingress rule"
bash set-ingress-ip.sh $EXTERNAL_IP autoconfirm

echo "Installing linkerd ingress rule in cluster $CLUSTER_CONTEXT_NAME"
kubectl apply -f ingressLinkerdRules-"$CLUSTER_CONTEXT_NAME".yaml --context $CLUSTER_CONTEXT_NAME

echo "Injecting into namespace $NAMESPACE in cluster $CLUSTER_CONTEXT_NAME"
kubectl get namespace $NAMESPACE --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd inject - | kubectl replace --context $CLUSTER_CONTEXT_NAME -f -
echo "Injecting into namespace ingress-nginx in cluster $CLUSTER_CONTEXT_NAME"
kubectl get namespace ingress-nginx --context $CLUSTER_CONTEXT_NAME -o yaml | linkerd inject - | kubectl replace --context $CLUSTER_CONTEXT_NAME -f -

echo "Restarting storefront, stockmanager and zipkin to add them to the mesh in cluster $CLUSTER_CONTEXT_NAME"
kubectl rollout restart deployments storefront stockmanager zipkin --context $CLUSTER_CONTEXT_NAME

echo "Restarting the ingress contrtoller to add it to the mesh in cluster $CLUSTER_CONTEXT_NAME"
kubectl rollout restart deployments -n ingress-nginx ingress-nginx-controller --context $CLUSTER_CONTEXT_NAME

echo "Linkerd UI for cluster $CLUSTER_CONTEXT_NAME is at https://linkerd."$EXTERNAL_IP".nip.io username is $USERNAME password is $PASSWORD"

echo "Linkerd Grafana UI for cluster $CLUSTER_CONTEXT_NAME is at https://linkerd."$EXTERNAL_IP".nip.io/grafana username is $USERNAME password is $PASSWORD"