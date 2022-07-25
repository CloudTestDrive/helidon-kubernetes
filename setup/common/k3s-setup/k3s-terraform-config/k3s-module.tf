module k3s {

  
  source = "K3S_GH_URL"
  # version = "TERRAFORM_K3S_MODULE_VERSION"
  compartment_id="COMPARTMENT_OCID"
  tenancy_id="OCI_TENANCY"
  home_region="OCI_HOME_REGION"
  region="OCI_REGION"
  k3s_name="CLUSTER_NAME"

  vcn_name="k3s-vcn-CLUSTER_NAME"
  vcn_cidrs=["VCN_CLASS_B_NETWORK_CIDR_START.0.0/16"]

  create_bastion_host=false
  # this is a simple one, don't use if for production environments
  datastore_type="sqlite"
  server_type="public"
  server_allowed_cidrs=["0.0.0.0/0"]
  
  k3s_version="K3S_KUBERNETES_VERSION"

  label_prefix="lab-CLUSTER_NAME"
  
  server_shape= {shape = "CONTROL_PLANE_SHAPE", ocpus = CONTROL_PLANE_OCPUS, memory = CONTROL_PLANE_MEMORY, boot_volume_size = CONTROL_PLANE_BOOT_SIZE}
  server_size = CONTROL_PLANE_COUNT
  server_timezone="CLUSTER_TZ"
  agent_shape= {shape = "WORKER_SHAPE", ocpus = WORKER_OCPUS, memory = WORKER_MEMORY, boot_volume_size = WORKER_BOOT_SIZE}
  agent_size = WORKER_COUNT
  agent_timezone="CLUSTER_TZ"
  
  secret_name="K3S_TOKEN_SECRET"
  vault_id="VAULT_OCID"
  kms_key_id="VAULT_KEY_OCID"
  ssh_public_key_path="K3S_SSH_PUBLIC_KEY_PATH"
  ssh_private_key_path="K3S_SSH_PRIVATE_KEY_PATH"
  
   providers = {
    oci.home = oci.home
  }
}