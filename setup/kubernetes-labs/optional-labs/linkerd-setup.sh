#!/bin/bash -f

CLUSTER_CONTEXT_NAME=one

if [ $# -gt 0 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "Using default context name of $CLUSTER_CONTEXT_NAME"
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
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
  echo "Found exixting $HOME/.linkerd2 removing"
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


echo "Installing linkerd into the cluster"
linkerd install | kubectl apply -f -

echo "Running post install check to ensure linkerd core is installed"
linkerd check

echo "Installing linkerd visual tools"
linkerd viz install | kubectl apply -f -

echo "Running post install check to ensure linkerd core are installed"
linkerd check

echo "Remember to edit the linkerd visuals deployment and clean out the enforced-hotst element"
echo " Use 'kubectl edit deployment web -n linkerd-viz'"

cd $HOME/helidon-kubernetes/service-mesh

echo "Create linkerd visuals certificates"
cd $HOME/helidon-kubernetes/service-mesh
$HOME/keys/step certificate create linkerd.$EXTERNAL_IP.nip.io tls-linkerd-$EXTERNAL_IP.crt tls-linkerd-$EXTERNAL_IP.key --profile leaf  --not-after 8760h --no-password --insecure --kty=RSA --ca $HOME/keys/root.crt --ca-key $HOME/keys/root.key

echo "Create linkerd visuals secret"
kubectl create secret tls tls-linkerd --key tls-linkerd-$EXTERNAL_IP.key --cert tls-linkerd-$EXTERNAL_IP.crt -n linkerd-viz

USERNAME=admin
PASSWORD=ZaphodBeeblebrox
echo "Setting linkerd UI password to $PASSWORD"
htpasswd -c -b auth $USERNAME $PASSWORD

echo "Creating linkerd UI password secret"
kubectl create secret generic web-ingress-auth -n linkerd-viz --from-file=auth

echo "Configuring linkerd ingress rule"
bash set-ingress-ip.sh $EXTERNAL_IP autoconfirm

echo "Installing linkerd ingress rule"
kubectl apply -f ingressLinkerdRules-`kubectl config current-context`.yaml

echo "Injecting into namespace $NAMESPACE"
kubectl get namespace $NAMESPACE -o yaml | linkerd inject - | kubectl replace -f -
echo "Injecting into namespace ingress-nginx"
kubectl get namespace ingress-nginx -o yaml | linkerd inject - | kubectl replace -f -

echo "Restarting storefront, stockmanager and zipkin to add them to the mesh"
kubectl rollout restart deployments storefront stockmanager zipkin

echo "Restarting the ingress contrtoller to add it to the mesh"
kubectl rollout restart deployments -n ingress-nginx ingress-nginx-controller

echo "Linkerd UI is at https://linkerd."$EXTERNAL_IP".nip.io username is $USERNAME password is $PASSWORD"

echo "Linkerd Grafana UI is at https://linkerd."$EXTERNAL_IP".nip.io/grafana username is $USERNAME password is $PASSWORD"