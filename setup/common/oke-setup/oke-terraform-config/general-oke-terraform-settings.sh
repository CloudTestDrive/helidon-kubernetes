TERRAFORM_OKE_MODULE_VERSION=4.5.1
#IMPORTANT Do not upgrade to 1.24 until cloud shell has the updated kubectl and the installBaseElements.sh script 
#understands how to handle kubectl create token <user> -n <namespace> --context <context>
OKE_KUBERNETES_VERSION=v1.25.4
VCN_CLASS_B_NETWORK_CIDR_START=10.10