K3S_GH_REPO=hyder/terraform-oci-k3s
#K3S_GH_URL=https://github.com/$K3S_GH_REPO
K3S_GH_URL=$HOME/terraform-oci-k3s-main
echo "Using pre-loaded K3S TF data in $K3S_GH_URL for now, this needs to be switched when the pubnloic GH repo is available"
TERRAFORM_K3S_MODULE_VERSION=4.2.4
# Be carefull updating to 1.24 until the kubectl command is at that version and understanda the create token sub command
# also ensure that the 
K3S_KUBERNETES_VERSION_BASE="1.23.4"
K3S_KUBERNETES_VERSION="v""$K3S_KUBERNETES_VERSION_BASE""+k3s1"
VCN_CLASS_B_NETWORK_CIDR_START=10.128
CREATE_BASION=false
PROVIDER_VERSION=">= 4.67.3"