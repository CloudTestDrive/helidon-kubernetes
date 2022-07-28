#!/bin/bash
SCRIPT_NAME=`basename $0`
CLUSTER_CONTEXT_NAME=one

if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT_NAME=$1
  echo "$SCRIPT_NAME Operating on context name $CLUSTER_CONTEXT_NAME"
else
  echo "$SCRIPT_NAME Using default context name of $CLUSTER_CONTEXT_NAME"
fi

if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi
if [ "$AUTO_CONFIRM" = "true" ]
then
  REPLY="y"
  echo "Auto confirm enabled, setting up config in downloaded git repo $CLUSTER_CONTEXT_NAME is the kubernetes current context name default to $REPLY"
else
 echo "setting up config in downloaded git repo $CLUSTER_CONTEXT_NAME is the kubernetes current context name"
 read -p "Proceed (y/n) ?" REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, exiting"
  exit 1
else
  echo "Fully install cluster, $CLUSTER_CONTEXT_NAME is the kubernetes cluster name"
fi


CLUSTER_NETWORK=$HOME/clusterNetwork.$CLUSTER_CONTEXT_NAME

if [ -f $CLUSTER_NETWORK ]
then
  source $CLUSTER_NETWORK
  echo "Located cluster networking config info file $CLUSTER_CONTEXT_NAME"
else
  echo "Cannot locate cluster networking config info file $CLUSTER_CONTEXT_NAME, this may be problematic if installing into a non OKE cluster"
fi

INFO_FILE=$HOME/clusterInfo.$CLUSTER_CONTEXT_NAME
echo "reseting cluster info file"
echo > $INFO_FILE

SETTINGS_FILE=$HOME/clusterSettings.$CLUSTER_CONTEXT_NAME
echo "reset cluster settings file"
echo > $SETTINGS_FILE

echo "Getting helm chart versions"
source helmChartVersions.sh

echo "Create ingress namespace"
kubectl create namespace ingress-nginx --context $CLUSTER_CONTEXT_NAME
echo "install Ingress using helm"
if [ -z "$LB_NSG_OCID" ]
then
  echo "Cannot locate the Load Balancer network security group, for non OKE clusters this may mean that services of type LoadBalancer (e.g. the ingress controller) cannot be contacted"
else
  echo "Located the load balancer network security group, this will be used when setting up the ingress controller"
  LB_NSG_OPTION='--set controller.service.annotations."oci\.oraclecloud\.com/oci-network-security-groups"='"$LB_NSG_OCID"
fi

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx  --kube-context $CLUSTER_CONTEXT_NAME --namespace ingress-nginx --version $ingressHelmChartVersion --set rbac.create=true  --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-protocol"=TCP --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"=flexible --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-min"=10  --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-max"=20 --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-security-list-management-mode"=All $LB_NSG_OPTION
echo "Helm for ingress completed - It may take a while to get the external IP address of the ingress load ballancer"
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  echo "Waiting for ingress external IP"
  EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller --namespace ingress-nginx --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}" --context $CLUSTER_CONTEXT_NAME)
  [ -z "$EXTERNAL_IP" ] && sleep 10
done
echo "Ingress controller external IP is " $EXTERNAL_IP
echo External IP >> $INFO_FILE
echo $EXTERNAL_IP >> $INFO_FILE
echo >> $INFO_FILE
echo "export EXTERNAL_IP=$EXTERNAL_IP" >>$INFO_FILE
echo >> $INFO_FILE
echo "installing dashboard using helm"
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard  --kube-context $CLUSTER_CONTEXT_NAME --namespace kube-system --set ingress.enabled=true --set ingress.annotations."kubernetes\.io/ingress\.class"=nginx --set ingress.hosts="{dashboard.kube-system.$EXTERNAL_IP.nip.io}" --version $dashboardHelmChartVersion
echo "Helm for dashboard completed - it may take a while for the dashboard to be running"

echo Dashboard URL >> $INFO_FILE
echo https://dashboard.kube-system.$EXTERNAL_IP.nip.io >> $INFO_FILE
echo >> $INFO_FILE

echo "Installing dashboard user"
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl apply -f dashboard-user.yaml --context $CLUSTER_CONTEXT_NAME
echo "getting dashboard token"
dashboardUserSecret=`kubectl -n kube-system get secret  --context $CLUSTER_CONTEXT_NAME | grep dashboard-user | awk '{print $1}'`
dashboardUserTokenEncoded=`kubectl -n kube-system get secret $dashboardUserSecret  --context $CLUSTER_CONTEXT_NAME -o=jsonpath='{.data.token}'`
dashboardUserToken=`echo $dashboardUserTokenEncoded | base64 -d`
echo "Dashboard token is $dashboardUserToken"
echo Dashboard Token >> $INFO_FILE
echo $dashboardUserToken >> $INFO_FILE
echo >> $INFO_FILE

echo "Installing metrics-server"
helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --version $metricsServerHelmChartVersion --kube-context $CLUSTER_CONTEXT_NAME

BASE_URL=https://store.$EXTERNAL_IP.nip.io

echo "saving External IP for later use"
echo "EXTERNAL_IP=$EXTERNAL_IP" >> $SETTINGS_FILE
echo 'echo EXTERNAL_IP set to $EXTERNAL_IP' >> $SETTINGS_FILE


echo 'BASE_URL=https://store.$EXTERNAL_IP.nip.io' >> $SETTINGS_FILE
echo 'echo BASE_URL set to $BASE_URL' >> $SETTINGS_FILE
echo ""  >> $INFO_FILE

# save the base url
echo "saving base url for later use"
echo "Base URL is $BASE_URL"  >> $INFO_FILE

# save the core curl cmd
echo "curl cmd" >> $INFO_FILE
echo "curl -i -X GET -u jack:password -k $BASE_URL/store/stocklevel" >> $INFO_FILE
echo >> $INFO_FILE

echo "status command"  >> $INFO_FILE
echo "curl -i -X GET -k $BASE_URL/sf/status"  >> $INFO_FILE
echo >> $INFO_FILE

echo "Test reserve stock command  - Assumes that you have resources called Pins"   >> $INFO_FILE
echo 'curl -u jack:password -i -k -H "Content-Type: application/json" -X POST -d "{\"requestedItem\":\"Pins\", \"requestedCount\": 5}"'" $BASE_URL/store/reserveStock"  >> $INFO_FILE
echo >> $INFO_FILE

# now we have the ingress we csan update the rules to fit it
echo "updating base ingress rules"
bash $HOME/helidon-kubernetes/base-kubernetes/set-ingress-ip.sh $EXTERNAL_IP $CLUSTER_CONTEXT_NAME
echo "updating persistence ingress rules"
bash $HOME/helidon-kubernetes/persistence/set-ingress-ip.sh $EXTERNAL_IP $CLUSTER_CONTEXT_NAME
echo "updating service mesh ingress rules"
bash $HOME/helidon-kubernetes/service-mesh/set-ingress-ip.sh $EXTERNAL_IP $CLUSTER_CONTEXT_NAME

	