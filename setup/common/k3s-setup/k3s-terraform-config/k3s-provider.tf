terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "PROVIDER_VERSION"
    }
  }
}
# If not runnign in the cloud shell need to handle the following
# but these labs are cloud shell based so for now we can leave these
# commented
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