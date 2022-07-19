#!/bin/bash
currentContext=`bash get-current-context.sh`
if [ $# -eq 0 ]
  then
    echo setting up config in downloaded git repo $currentContext is the kubernetes current context name
    read -p "Proceed (y/n) ?" 
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping fully install cluster confirmation $currentContext is the kubernetes cluster name"
fi


CLUSTER_NETWORK=$HOME/clusterNetwork.$currentContext

if [ -f $CLUSTER_NETWORK ]
then
  source $CLUSTER_NETWORK
  echo "Located cluster networking config info file $currentContext"
else
  echo "Cannot locate cluster networking config info file $currentContext, this may be problematic if installing into a non OKE cluster"
fi

if [ -z "$LB_NSG_OCID" ]
then
  echo "Cannot locate the Load Balancer network security group, for non OKE clusters this may mean that services of type LoadBalancer (e.g. the ingress controller) cannot be contacted"
else
  echo "Located the load balancer network security group, this will be used when setting up the ingress controller"
fi

infoFile=$HOME/clusterInfo.$currentContext
echo reseting cluster info file
echo > $infoFile

settingsFile=$HOME/clusterSettings.$currentContext
echo reset cluster settings file
echo > $settingsFile

echo Getting helm chart versions
source helmChartVersions.sh

echo Create ingress namespace
kubectl create namespace ingress-nginx
echo install Ingress using helm
LB_NSG_OPTION='--set controller.service.annotations."oci\.oraclecloud\.com/oci-network-security-groups"='"$LB_NSG_OCID"
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --version $ingressHelmChartVersion --set rbac.create=true  --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-protocol"=TCP --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"=flexible --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-min"=10  --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape-flex-max"=20 $LB_NSG_OPTION
echo Helm for ingress completed - It may take a while to get the external IP address of the ingress load ballancer
EXTERNAL_IP=""
while [ -z "$EXTERNAL_IP" ]; do
  echo "Waiting for ingress external IP"
  EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller --namespace ingress-nginx --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$EXTERNAL_IP" ] && sleep 10
done
echo 'Ingress controller external IP is ' $EXTERNAL_IP
echo External IP >> $infoFile
echo $EXTERNAL_IP >> $infoFile
echo >> $infoFile
echo "export EXTERNAL_IP=$EXTERNAL_IP" >>$infoFile
echo >> $infoFile
echo installing dashboard using helm
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kube-system --set ingress.enabled=true --set ingress.annotations."kubernetes\.io/ingress\.class"=nginx --set ingress.hosts="{dashboard.kube-system.$EXTERNAL_IP.nip.io}" --version $dashboardHelmChartVersion
echo Helm for dashboard completed - it may take a while for the dashboard to be running

echo Dashboard URL >> $infoFile
echo https://dashboard.kube-system.$EXTERNAL_IP.nip.io >> $infoFile
echo >> $infoFile

echo Installing dashboard user
cd $HOME/helidon-kubernetes/base-kubernetes
kubectl apply -f dashboard-user.yaml
echo getting dashboard token
dashboardUserSecret=`kubectl -n kube-system get secret | grep dashboard-user | awk '{print $1}'`
dashboardUserTokenEncoded=`kubectl -n kube-system get secret $dashboardUserSecret -o=jsonpath='{.data.token}'`
dashboardUserToken=`echo $dashboardUserTokenEncoded | base64 -d`
echo Dashboard token is $dashboardUserToken
echo Dashboard Token >> $infoFile
echo $dashboardUserToken >> $infoFile
echo >> $infoFile

echo "Installing metrics-server"
helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --version $metricsServerHelmChartVersion

BASE_URL=https://store.$EXTERNAL_IP.nip.io

echo "saving External IP for later use"
echo "EXTERNAL_IP=$EXTERNAL_IP" >> $settingsFile
echo 'echo EXTERNAL_IP set to $EXTERNAL_IP' >> $settingsFile


echo 'BASE_URL=https://store.$EXTERNAL_IP.nip.io' >> $settingsFile
echo 'echo BASE_URL set to $BASE_URL' >> $settingsFile
echo ""  >> $infoFile

# save the base url
echo "saving base url for later use"
echo "Base URL is $BASE_URL"  >> $infoFile

# save the core curl cmd
echo "curl cmd" >> $infoFile
echo "curl -i -X GET -u jack:password -k $BASE_URL/store/stocklevel" >> $infoFile
echo >> $infoFile

echo "status command"  >> $infoFile
echo "curl -i -X GET -k $BASE_URL/sf/status"  >> $infoFile
echo >> $infoFile


# now we have the ingress we csan update the rules to fit it
echo updating base ingress rules
bash $HOME/helidon-kubernetes/base-kubernetes/set-ingress-ip.sh $EXTERNAL_IP skip
echo updating service mesh ingress rules
bash $HOME/helidon-kubernetes/service-mesh/set-ingress-ip.sh $EXTERNAL_IP skip

	