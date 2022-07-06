#!/bin/bash -f
# any vars set in here need to be exported to make it into the clusterctl command
# the following are the requird settings, ones that are commented out will be set by the 
# main CAPI setup script, but can be overridden here or in the cluster-specific-capi-settings-???.sh file
# can;t see whyt anytione woudl override this, given these are beneraited dynamicallywhen the compartment is created, but they can if they need to 
#export OCI_COMPARTMENT_ID=<compartment-id>
# the id of the image to use
# this shoudl probabaly be set here
# but until we find out how to leave it for now
#export OCI_IMAGE_ID=<ubuntu-custom-image-id>
# the ssh key - will be created automatically and set by the scripts
# but I guess someone might want to use a single key for it all
#export OCI_SSH_KEY=<ssh-key>
# how many conrteol planes vm's do you want ?
#export CONTROL_PLANE_MACHINE_COUNT=1
# the version of kubernrtes to install in the cluster, probabaly this will need updating
# over time
export KUBERNETES_VERSION=v1.22.5
export OCI_IMAGE_ID=ocid1.image.oc1.uk-london-1.aaaaaaaa47douc3hrwoia2sdi64uwjac5gdgjhvksydvu372fwjrxxzvchma
# this is the namespace in the OKE management cluster and the resources will be created in, it will be created if needs be
#export NAMESPACE=default
# number of workers maybe - this is a little unclear
#export NODE_MACHINE_COUNT=1