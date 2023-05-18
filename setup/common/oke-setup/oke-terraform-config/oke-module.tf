module oke {

  source  = "oracle-terraform-modules/oke/oci"
  version = "TERRAFORM_OKE_MODULE_VERSION"
  compartment_id="COMPARTMENT_OCID"
  tenancy_id="OCI_TENANCY"
  home_region="OCI_HOME_REGION"
  region="OCI_REGION"
  cluster_name="CLUSTER_NAME"

  vcn_name="oke-vcn-CLUSTER_NAME"
  vcn_cidrs=["VCN_CLASS_B_NETWORK_CIDR_START.0.0/16"]

  create_bastion_host=false
  create_bastion_service=false
  create_operator=false
  control_plane_type="public"
  control_plane_allowed_cidrs=["0.0.0.0/0"]
  
  kubernetes_version="OKE_KUBERNETES_VERSION"

  label_prefix="lab-K8S_CONTEXT"
  
  use_signed_images=USE_SIGNED_IMAGES
  image_signing_keys=IMAGE_SIGNING_KEYS
  
  # calico
  enable_calico            = ENABLE_CALICO
  calico_version           = "CALICO_VERSION"
  calico_mode              = "CALICO_MODE"

  node_pools = {
    POOL_NAME = { shape = "WORKER_SHAPE", ocpus = WORKER_OCPUS, memory = WORKER_MEMORY, node_pool_size = WORKER_COUNT, boot_volume_size = WORKER_BOOT_SIZE, label = {pool = "POOL_NAME" } }
  } 

   providers = {
    oci.home = oci.home
  }
}