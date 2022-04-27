1provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
}
provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_HOME_REGION"
   alias  = "home"
}