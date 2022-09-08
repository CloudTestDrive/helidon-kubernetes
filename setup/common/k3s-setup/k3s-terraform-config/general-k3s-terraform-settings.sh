K3S_GH_REPO=hyder/terraform-oci-k3s
#K3S_GH_URL=https://github.com/$K3S_GH_REPO
K3S_GH_URL=$HOME/k3s-cluster
echo "Using pre-loaded K3S TF data in $K3S_GH_URL for now, this needs to be switched when the pubnloic GH repo is available"
# Be carefull updating to 1.24 until the kubectl command is at that version and understanda the create token sub command
# also ensure that the 
#K3S_KUBERNETES_VERSION_BASE="1.23.4"
#K3S_KUBERNETES_VERSION="v""$K3S_KUBERNETES_VERSION_BASE""+k3s1"
K3S_KUBERNETES_VERSION="latest"
#PROVIDER_VERSION=">= 4.67.3"
PROVIDER_VERSION=">= 4.91.0"
# default networking values, if using multiple clusters these reall should be overidden
VCN_CIDR="10.0.110.0/16"
SERVER_SUBNET_CIDR="10.0.110.0/24"
WORKER_SUBNET_CIDR="10.0.111.0/24"
#OPERATING_SYSTEM=oraclelinux
#OPERATING_SYSTEM_VERSION=8