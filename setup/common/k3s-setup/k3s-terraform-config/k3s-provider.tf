terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "PROVIDER_VERSION"
    }
  }
}

provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_REGION"
}
provider "oci" {
   auth = "InstancePrincipal"
   region = "OCI_HOME_REGION"
   alias  = "home"
}