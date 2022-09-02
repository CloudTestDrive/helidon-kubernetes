module k3s {

  source = "K3S_GH_URL"
  
  region="OCI_REGION"
  availability_domain="AVAILABILITY_DOMAIN"
  environment="K3S_ENVIRONMENT"
  tenancy_ocid="OCI_TENANCY"
  compartment_ocid="COMPARTMENT_OCID"
  k3s_version="K3S_KUBERNETES_VERSION"
  cluster_name="CLUSTER_NAME"
  PATH_TO_PUBLIC_KEY="K3S_SSH_PUBLIC_KEY_PATH"
  PATH_TO_PRIVATE_KEY="K3S_SSH_PRIVATE_KEY_PATH"
  
  compute_shape="COMPUTE_SHAPE"
  operating_system="OPERATING_SYSTEM"
  os_image_id="IMAGE_OCID"
  server_ocpus=CONTROL_PLANE_OCPUS 
  server_memory_in_gbs=CONTROL_PLANE_MEMORY
  k3s_server_pool_size=CONTROL_PLANE_EXTRA_NODE_COUNT
  worker_ocpus=WORKER_OCPUS
  worker_memory_in_gbs=WORKER_MEMORY
  k3s_worker_pool_size=WORKER_COUNT
  
  my_public_ip_cidr="0.0.0.0/0"
  
  oci_core_vcn_cidr="VCN_CIDR"
  oci_core_subnet_cidr10="SERVER_SUBNET_CIDR"
  oci_core_subnet_cidr11="WORKER_SUBNET_CIDR"
  
  oci_identity_dynamic_group_name="K3S_CLUSTER_DYNAMIC_GROUP_NAME"
  oci_identity_policy_name="K3S_CLUSTER_POLICY_NAME"
  
  install_nginx_ingress=INSTALL_NGINX_INGRESS
  install_certmanager=INSTALL_CERT_MGR
  certmanager_release="CERT_MGR_VERSION"
  certmanager_email_address="CERT_MGR_EMAIL"
  install_longhorn=INSTALL_LONGHORN
  longhorn_release="LONGHORN_VERSION"
  install_oci_ccm=INSTALL_OCI_CCM
  oci_ccm_release="OCI_CCM_VERSION"
  
  expose_kubeapi=PUBLIC_KUBEAPI
    
  # providers = {
  #  oci.home = oci.home
  #}
}