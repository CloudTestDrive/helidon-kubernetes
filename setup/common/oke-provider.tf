provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
}
provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
   alias  = "home"
}