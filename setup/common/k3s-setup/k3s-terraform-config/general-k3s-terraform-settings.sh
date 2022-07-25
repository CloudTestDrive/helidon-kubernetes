K3S_GH_REPO=hyder/terraform-oci-k3s
#K3S_GH_URL=https://github.com/$K3S_GH_REPO
K3S_GH_URL=$HOME/terraform-oci-k3s-main
echo "Using pre-loaded K3S TF data in $K3S_GH_URL for now, this needs to be switched when the pubnloic GH repo is available"
TERRAFORM_K3S_MODULE_VERSION=4.2.4
K3S_KUBERNETES_VERSION=v1.23.4
VCN_CLASS_B_NETWORK_CIDR_START=10.128
CREATE_BASION=false