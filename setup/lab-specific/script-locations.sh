#!/bin/bash -f
echo "Configuring location information"
export SETUP_DIR=$HOME/helidon-kubernetes/setup
export COMMON_DIR=$SETUP_DIR/common
export DEVOPS_LABS_DIR=$SETUP_DIR/devops-labs
export KUBERNETES_LABS_DIR=$SETUP_DIR/kubernetes-labs
export LAB_SPECIFIC_DIR=$SETUP_DIR/lab-specific
export MODULES_DIR=$LAB_SPECIFIC_DIR/modules