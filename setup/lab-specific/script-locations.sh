#!/bin/bash -f
echo "Configuring location information"
export GIT_REPO_DIR=$HOME/helidon-kubernetes
export SETUP_DIR=$GIT_REPO_DIR/setup
export COMMON_DIR=$SETUP_DIR/common
export DEVOPS_LABS_DIR=$SETUP_DIR/devops-labs
export DR_LABS_DIR=$SETUP_DIR/dr-labs
export KUBERNETES_LABS_DIR=$SETUP_DIR/kubernetes-labs
export KUBERNETES_OPTIONAL_LABS_DIR=$KUBERNETES_LABS_DIR/optional-labs
export KUBEFLOW_LABS_DIR=$SETUP_DIR/kubeflow-labs
export LAB_SPECIFIC_DIR=$SETUP_DIR/lab-specific
export OPEN_SEARCH_DIR=$KUBERNETES_LABS_DIR/opensearch
export MODULES_DIR=$LAB_SPECIFIC_DIR/modules
export PERSISTENCE_DIR=$GIT_REPO_DIR/persistence