provider "oracle/oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
}
provider "oracle/oci" {
   auth = "InstancePrincipal"
   region = "OCI_HOME_REGION"
   alias  = "home"
}