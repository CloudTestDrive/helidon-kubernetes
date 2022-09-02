provider "oracle/oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
}
provider "oracle/oci" {
   auth = "InstancePrincipal"
   region = "OCI_HOME_REGION"
   alias  = "home"
}

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 4.64.0"
    }
  }
}