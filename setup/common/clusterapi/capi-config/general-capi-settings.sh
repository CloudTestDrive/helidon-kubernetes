# the following are the requird settings, ones that are commented out will be set by the 
# main CAPI setup script, but can be overridden here or in the cluster-specific-capi-settings-???.sh fio]le
#OCI_COMPARTMENT_ID=<compartment-id>
OCI_IMAGE_ID=<ubuntu-custom-image-id>
OCI_SSH_KEY=<ssh-key>
CONTROL_PLANE_MACHINE_COUNT=1
KUBERNETES_VERSION=v1.23.5
# this is the namespace in the OKE management cluster and the resources will be created in, it will be created if needs be
#NAMESPACE=default
NODE_MACHINE_COUNT=1