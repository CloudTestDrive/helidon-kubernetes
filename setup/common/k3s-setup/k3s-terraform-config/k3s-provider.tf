#terraform {
#  required_providers {
#    oci = {
#      source  = "oracle/oci"
#      version = "PROVIDER_VERSION"
#    }
#  }
#}

#provider "oci" {
#   auth = "InstancePrincipal"
#   region = "OCI_REGION"
#}
#provider "oci" {
#   auth = "InstancePrincipal"
#   region = "OCI_HOME_REGION"
#   alias  = "home"
#}
terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "PROVIDER_VERSION"
    }
  }
}

## API key provider
# provider "oci" {
#   tenancy_ocid     = ""
#   user_ocid        = ""
#   private_key_path = ""
#   fingerprint      = ""
#   region           = "OCI_REGION"
# }
################

## Instance Principal provider
provider "oci" {
  auth   = "InstancePrincipal"
  region = "OCI_REGION"
}