# Version info to use with the cluster api
CLUSTERCTL_VERSION=1.1.5
ORACLE_CAPI_VERSION=0.3.0
CALICO_VERSION=3.21
ORACLE_CCM_VERSION=1.22.1

# locations and things
CAPI_DIR=$HOME/.cluster-api
CAPI_YAML=clusterctl.yaml
CAPI_PATH=$CAPI_DIR/$CAPI_YAML

CLUSTERCTL_DIR=$HOME/capi
CLUSTERCTL_CMD=clusterctl
CLUSTERCTL_PATH=$CLUSTERCTL_DIR/$CLUSTERCTL_CMD

CLUSTERAPI_YAML_DIR=$HOME/clusterapi_yaml

# where to install the capi stuff in the management cluster
CAPI_NAMESPACE=capi