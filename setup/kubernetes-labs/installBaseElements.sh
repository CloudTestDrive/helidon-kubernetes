#!/bin/bash
currentContext=`bash get-current-context.sh`
if [ $# -eq 0 ]
  then
    echo setting up config in downloaded git repo $currentContext is the kubernetes current context name
    read -p "Proceed ? " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
        echo OK, exiting
        exit 1
    fi
  else
    echo "Skipping fully install cluster confirmation $currentContext is the kubernetes cluster name"
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
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --version $ingressHelmChartVersion --set rbac.create=true --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-protocol"=TCP --set controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"=10Mbps
echo Helm for ingress completed - It may take a while to get the external IP address of the ingress load ballancer
ip=""
while [ -z "$ip" ]; do
  echo "Waiting for ingress external IP"
  ip=$(kubectl get svc ingress-nginx-controller --namespace ingress-nginx --template="{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}")
  [ -z "$ip" ] && sleep 10
done
echo 'Ingress controller external IP is ' $ip
echo External IP >> $infoFile
echo $ip >> $infoFile
echo >> $infoFile
echo "export EXTERNAL_IP=$ip" >>$infoFile
echo >> $infoFile
echo installing dashboard using helm
helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --namespace kube-system --set ingress.enabled=true --set ingress.hosts="{dashboard.kube-system.$ip.nip.io}" --version $dashboardHelmChartVersion
echo Helm for dashboard completed - it may take a while for the dashboard to be running

echo Dashboard URL >> $infoFile
echo https://dashboard.kube-system.$ip.nip.io >> $infoFile
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

# save the core curl cmd
echo curl cmd >> $infoFile
echo curl -i -X GET -u jack:password -k https://store.$ip.nip.io/store/stocklevel >> $infoFile
echo >> $infoFile

echo status command  >> $infoFile
echo curl -i -X GET -k https://store.$ip.nip.io/sf/status  >> $infoFile
echo >> $infoFile

echo saving External IP for later use
echo ip=$ip >> $settingsFile

# now we have the ingress we csan update the rules to fit it
echo updating base ingress rules
bash $HOME/helidon-kubernetes/base-kubernetes/set-ingress-ip.sh $ip skip
echo updating service mesh ingress rules
bash $HOME/helidon-kubernetes/service-mesh/set-ingress-ip.sh $ip skip

	