#!/bin/bash -f

CLUSTER_CONTEXT=one
if [ $# -ge 1 ]
then
  CLUSTER_CONTEXT=$1
fi

# try to locate the cluster settings file for this cluster
CLUSTER_SETTINGS="$HOME/clusterSettings"".""$CLUSTER_CONTEXT"
if [ -f "$CLUSTER_SETTINGS" ]
then
  echo "Located $CLUSTER_SETTINGS, loading settings from it"
  source $CLUSTER_SETTINGS
else
  echo "Can't locate cluster settings file $CLUSTER_SETTINGS unless EXTERNAL_IP is set elsewhere this may be a problem"
fi
if [ -z "$EXTERNAL_IP" ]
then
  echo "Variable EXTERNAL_IP which should contain the IP address of the ingress controller in your cluster is not"
  echo "set, either the $CLUSTER_SETTINGS does not exist (or if it does does not set EXTERNAL_IP) or it's not set"
  echo "in other ways, cannot continue"
  exit 1
fi

export SETTINGS=$HOME/hk8sLabsSettings

if [ -f $SETTINGS ]
  then
    echo "Loading existing settings information"
    source $SETTINGS
  else 
    echo "No existing settings cannot continue"
    exit 10
fi

if [ -z $COMPARTMENT_OCID ]
then
  echo "Your COMPARTMENT_OCID has not been set, you need to run the compartment-setup.sh before you can run this script"
  exit 2
fi

if [ -z $USER_INITIALS ]
then
  echo "Your USER_INITIALS has not been set, you need to run the initials-setup.sh before you can run this script"
  exit 3
fi


if [ -z "$AUTO_CONFIRM" ]
then
  export AUTO_CONFIRM=false
fi

if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Have you setup the basic core elements (database, container images, database) and installed the example setup in the tenancy defaulting to $REPLY"
else
  read -p "Have you setup the basic core elements (database, container images, database) and installed the example setup in the tenancy (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit, please setup the environment, the lab-specific/optional-kubernetes-lab-setup.sh script can do this for you"
  exit -1
fi
if [ "$AUTO_CONFIRM" = true ]
then
  REPLY="y"
  echo "Auto confirm is enabled, Have you setup the security SSH keys, created the vault, dynamic groups and policies for devops defaulting to $REPLY"
else
  read -p "Have you setup the security SSH keys, created the vault, dynamic groups and policies for devops (y/n) ? " REPLY
fi
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
  echo "OK, this script will exit, please setup SSH keys, created the vault, dynamic groups and policies for devops, the vault-setup.sh and security-setup.sh scripts can do this for you"
  exit -2
fi
if [ -z "$DEVOPS_DYNAMIC_GROUPS_CONFIGURED" ]
then
  echo "Dynamic groups not yet configured"
  exit 4
else
  echo "Dynamic groups have been configured"
fi


if [ -z "$DEVOPS_POLICIES_CONFIGURED" ]
then
  echo "DevOps policies not configured"
  exit 5
else
  echo "DevOps policies have been configured"
fi

if [ -z "$DEVOPS_SSH_API_KEY_CONFIGURED" ]
then
  echo "SSH API Key for devops not previously configured"
  exit 6
else
  echo "These scripts have previously setup the SSH API Key for devops"
fi


if [ -z "$VAULT_OCID" ]
then
  echo "No vault OCID set, have you run the vault-setup.sh script ?"
  exit 7
else
  echo "Found vault"
fi
ITEM_NAMES_FILE=names.sh
if [ -f "$ITEM_NAMES_FILE" ]
then
  echo "Located the names file $ITEM_NAMES_FILE, loading it"
  source $ITEM_NAMES_FILE
else
  echo "Unable to locate the names file $ITEM_NAMES_FILE this means the script will now have any of the names to process, cannot continue"
  exit 7
fi

echo "Passed checks starting to create environment"

SAVED_DIR=`pwd`
COMMON_DIR=`pwd`/../../common
DEVOPS_LAB_DIR=$SAVED_DIR/..

echo "This script attempts to follow the order of the dev-ops lab"
echo "Create notifications topic"
cd $COMMON_DIR/notifications
bash ./topic-setup.sh "$TOPIC_NAME" 'Communication between DevOps service elements'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Topic setup module returned an error, unable to continue"
  exit $RESP
fi
echo "Create project"
cd $SAVED_DIR
cd $COMMON_DIR/devops
bash ./project-setup.sh $PROJECT_NAME $TOPIC_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps project setup module returned an error, unable to continue"
  exit $RESP
fi
echo "Enabling project logging"
PROJECT_OCID=`bash ./get-project-ocid.sh $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "DevOps project get ocid returned an error, unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
cd $COMMON_DIR/logging
echo "Creating log group"
bash ./log-group-setup.sh "$LOG_GROUP_NAME" "$LOG_GROUP_DESCRIPTION"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating log group, unable to continue"
  exit $RESP
fi
echo "Creating log "
bash ./log-oci-service-setup.sh $LOG_NAME $LOG_GROUP_NAME devops $PROJECT_OCID
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating log , unable to continue"
  exit $RESP
fi

cd $SAVED_DIR
cd $COMMON_DIR/devops
echo "Creating code repo"
bash ./repo-setup.sh $CODE_REPO_NAME $PROJECT_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating code repo , unable to continue"
  exit $RESP
fi
cd $SAVED_DIR
cd $DEVOPS_LAB_DIR
echo "Uploading the git repo"
bash ./upload-git-repo.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem uploading git repo initial code, unable to continue"
  exit $RESP
fi


cd $SAVED_DIR
cd $DEVOPS_LAB_DIR
echo "Setting up vault secrets"
bash ./vault-secrets-setup.sh
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating vault secrets, unable to continue"
  exit $RESP
fi

echo "Retrieving vault secrets OCID's"
cd $COMMON_DIR/vault

HOST_SECRET_OCID=`bash ./get-vault-secret-ocid.sh $HOST_SECRET_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for vault secret $HOST_SECRET_NAME, unable to continue"
  exit $RESP
fi
NAMESPACE_SECRET_OCID=`bash ./get-vault-secret-ocid.sh $NAMESPACE_SECRET_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for vault secret $NAMESPACE_SECRET_NAME, unable to continue"
  exit $RESP
fi

echo "Creating new branch $GIT_BRANCH_NAME for modifications"
cd $CODE_BASE
git checkout -b $GIT_BRANCH_NAME

echo "Updating build spec"
cp $SOURCE_BUILD_SPEC $CODE_BASE

bash $COMMON_DIR/update-file.sh $WORKING_BUILD_SPEC 'Needs your host secrets OCID' $HOST_SECRET_OCID

bash $COMMON_DIR/update-file.sh $WORKING_BUILD_SPEC 'Needs your storage namespace OCID' $NAMESPACE_SECRET_OCID

echo "Updating version number"
bash $COMMON_DIR/update-file.sh  $STATUS_RESOURCE '1.0.0' '1.0.1'


echo "Updating local repo and uploading to remote repo"
git add .
git commit -a -m 'Set secret OCIDs and updated version'
git push devops $GIT_BRANCH_NAME

echo "Creating build pipeline"
cd $COMMON_DIR/devops
bash ./build-pipeline-setup.sh $BUILD_PIPELINE_NAME $PROJECT_NAME 'Builds the storefront service'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating build pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
BUILD_PIPELINE_OCID=`bash ./get-build-pipeline-ocid.sh $BUILD_PIPELINE_NAME $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for build pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi

echo "Creating Build runner stage"
BUILD_SOURCE_INFO=`bash ./assemble-source-devops-code-repo-info.sh $CODE_REPO_NAME $PROJECT_NAME $GIT_BRANCH_NAME`
BUILD_SOURCE_ARRAY=`bash ../build-items-array.sh "$BUILD_SOURCE_INFO"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem assembling build runner stage $BUILD_STAGE_RUNNER_NAME info for repo $CODE_REPO_NAME with branch $GIT_BRANCH_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
BUILD_RUNNER_STAGE_PREDECESSOR=`bash ./builders/build-stage-predecessor.sh "$BUILD_PIPELINE_OCID"`
BUILD_RUNNER_STAGE_PREDECESSOR_ARRAY=`bash ../build-items-array.sh "$BUILD_RUNNER_STAGE_PREDECESSOR"`
bash ./build-stage-build-runner-setup.sh "$BUILD_STAGE_RUNNER_NAME" "$BUILD_PIPELINE_NAME" "$PROJECT_NAME" "$BUILD_SOURCE_ARRAY" "$BUILD_RUNNER_STAGE_PREDECESSOR_ARRAY" 

BUILD_RUNNER_STAGE_OCID=`bash ./get-build-stage-ocid.sh "$BUILD_STAGE_RUNNER_NAME" "$BUILD_PIPELINE_NAME" "$PROJECT_NAME"`

echo "Creating OCIR repo"
cd $COMMON_DIR/ocir
# create it as public and not immutable
bash  ./ocir-setup.sh $OCIR_REPO_NAME true false
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating OCIR repo $OCIR_REPO_NAME, unable to continue"
  exit $RESP
fi
OCIR_REPO_OCID=`bash ./get-ocir-ocid.sh $OCIR_REPO_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for OCIR repo $OCIR_REPO_NAME, unable to continue"
  exit $RESP
fi

echo "Creating artifact repo"
cd $COMMON_DIR/artifactrepo
bash ./artifact-repo-generic-setup.sh $ARTIFACT_REPO_NAME
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact repo $ARTIFACT_REPO_NAME, unable to continue"
  exit $RESP
fi

ARTIFACT_REPO_OCID=`bash ./get-artifact-repo-ocid.sh $ARTIFACT_REPO_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact repo $ARTIFACT_REPO_NAME, unable to continue"
  exit $RESP
fi

cd $COMMON_DIR/devops
# setup the  build pipeline params
BUILD_INITIALS_PARAM=`bash ./builders/build-pipeline-parameter.sh "$PARAM_BUILD_INITIALS_NAME" "$USER_INITIALS" "$PARAM_BUILD_INITIALS_DESCRIPTION"`
BUILD_PARAMS_LIST=`../build-items-list.sh "$BUILD_INITIALS_PARAM"`
./build-pipeline-params-setup.sh "$BUILD_PIPELINE_NAME" "$PROJECT_NAME" "$BUILD_PARAMS_LIST"


cd $COMMON_DIR/devops
# build the artifact entries
echo "Building artifact repo template entries"
echo "$ARTIFACT_STOREFRONT_OCIR_NAME"
bash ./deploy-artifact-ocir-setup.sh "$ARTIFACT_STOREFRONT_OCIR_NAME" "$PROJECT_NAME" "$ARTIFACT_STOREFRONT_OCIR_PATH" "Storefront container image"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy artifact $ARTIFACT_STOREFRONT_OCIR_NAME, unable to continue"
  exit $RESP
fi
ARTIFACT_STOREFRONT_OCIR_OCID=`bash ./get-deploy-artifact-ocid.sh "$ARTIFACT_STOREFRONT_OCIR_NAME" "$PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact ocir $ARTIFACT_STOREFRONT_OCIR_NAME, unable to continue"
  exit $RESP
fi
echo "$ARTIFACT_STOREFRONT_SERVICE_NAME"
bash ./deploy-artifact-generic-setup.sh "$ARTIFACT_STOREFRONT_SERVICE_NAME" "$PROJECT_NAME"  "$ARTIFACT_REPO_NAME"  "$ARTIFACT_STOREFRONT_SERVICE_PATH" "$ARTIFACT_STOREFRONT_SERVICE_VERSION" "Storefront service" KUBERNETES_MANIFEST
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy artifact $ARTIFACT_STOREFRONT_SERVICE_NAME, unable to continue"
  exit $RESP
fi
ARTIFACT_STOREFRONT_SERVICE_OCID=`bash ./get-deploy-artifact-ocid.sh "$ARTIFACT_STOREFRONT_SERVICE_NAME" "$PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact service $ARTIFACT_STOREFRONT_SERVICE_NAME, unable to continue"
  exit $RESP
fi
echo "$ARTIFACT_STOREFRONT_INGRESS_NAME"
bash ./deploy-artifact-generic-setup.sh "$ARTIFACT_STOREFRONT_INGRESS_NAME" "$PROJECT_NAME"  "$ARTIFACT_REPO_NAME"  "$ARTIFACT_STOREFRONT_INGRESS_PATH" "$ARTIFACT_STOREFRONT_INGRESS_VERSION" "Storefront ingress rule" KUBERNETES_MANIFEST
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy artifact $ARTIFACT_STOREFRONT_INGRESS_NAME, unable to continue"
  exit $RESP
fi
ARTIFACT_STOREFRONT_INGRESS_OCID=`bash ./get-deploy-artifact-ocid.sh "$ARTIFACT_STOREFRONT_INGRESS_NAME" "$PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact ingress $ARTIFACT_STOREFRONT_INGRESS_NAME, unable to continue"
  exit $RESP
fi
echo "$ARTIFACT_STOREFRONT_DEPLOYMENT_NAME"
bash ./deploy-artifact-generic-setup.sh "$ARTIFACT_STOREFRONT_DEPLOYMENT_NAME" "$PROJECT_NAME"  "$ARTIFACT_REPO_NAME"  "$ARTIFACT_STOREFRONT_DEPLOYMENT_PATH" "$ARTIFACT_STOREFRONT_DEPLOYMENT_VERSION" "Storefront deployment" KUBERNETES_MANIFEST
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy artifact $ARTIFACT_STOREFRONT_DEPLOYMENT_NAME, unable to continue"
  exit $RESP
fi
ARTIFACT_STOREFRONT_DEPLOYMENT_OCID=`bash ./get-deploy-artifact-ocid.sh "$ARTIFACT_STOREFRONT_DEPLOYMENT_NAME" "$PROJECT_NAME"`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for artifact deployment $ARTIFACT_STOREFRONT_DEPLOYMENT_NAME, unable to continue"
  exit $RESP
fi

echo "Building artifact repo template to build spec mappings"
ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_IMAGE=`bash ./builders/build-deliver-deploy-artifact-connection.sh $ARTIFACT_STOREFRONT_OCIR_OCID $ARTIFACT_STOREFRONT_OCIR_BUILD_SPEC_EXPORT_NAME`
ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_SERVICE=`bash ./builders/build-deliver-deploy-artifact-connection.sh $ARTIFACT_STOREFRONT_SERVICE_OCID $ARTIFACT_STOREFRONT_SERVICE_BUILD_SPEC_EXPORT_NAME`
ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_INGRESS=`bash ./builders/build-deliver-deploy-artifact-connection.sh $ARTIFACT_STOREFRONT_INGRESS_OCID $ARTIFACT_STOREFRONT_INGRESS_BUILD_SPEC_EXPORT_NAME`
ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_DEPLOYMENT=`bash ./builders/build-deliver-deploy-artifact-connection.sh $ARTIFACT_STOREFRONT_DEPLOYMENT_OCID $ARTIFACT_STOREFRONT_OCIR_BUILD_SPEC_EXPORT_NAME`
echo "Building artifact repo template to build spec mappings array"
ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_ARRAY=`bash ../build-items-array.sh "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_IMAGE" "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_SERVICE" "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_INGRESS" "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_DEPLOYMENT"`
echo "Result is"
echo "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_ARRAY"


BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_PREDECESSOR=`bash ./builders/build-stage-predecessor.sh "$BUILD_RUNNER_STAGE_OCID"`
BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_PREDECESSOR_ARRAY=`bash ../build-items-array.sh "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_PREDECESSOR"`


echo "Creating artifact to deployment deploy stage with command :"
echo bash ./build-stage-deliver-artifacts-setup.sh "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_NAME"  "$BUILD_PIPELINE_NAME" "$PROJECT_NAME" "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_ARRAY" "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_PREDECESSOR_ARRAY" "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_DESCRIPTION"

bash ./build-stage-deliver-artifacts-setup.sh "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_NAME"  "$BUILD_PIPELINE_NAME" "$PROJECT_NAME" "$ARTIFACT_TO_DEPLOYMENT_BUILD_SPEC_ARRAY" "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_PREDECESSOR_ARRAY" "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_DESCRIPTION"
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deliver artifacts stage for stage named $BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_NAME in pipeline $BUILD_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_OCID=`bash ./get-build-deliver-stage-ocid.sh "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_NAME" "$BUILD_PIPELINE_NAME" "$PROJECT_NAME"`

echo "Creaing the devops to deploy environment called $DEVOPS_DEPLOY_ENV_NAME targeting OKE cluster named $CLUSTER_CONTEXT"

bash ./deploy-environment-on-oke-setup.sh "$DEVOPS_DEPLOY_ENV_NAME" "$PROJECT_NAME" "$CLUSTER_CONTEXT" 

echo "Creating deploy pipeline"

cd $COMMON_DIR/devops
bash ./deploy-pipeline-setup.sh $DEPLOY_PIPELINE_NAME $PROJECT_NAME 'Deploys the storefront service'
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem creating deploy pipeline $DEPLOY_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi
DEPLOY_PIPELINE_OCID=`bash ./get-deploy-pipeline-ocid.sh $DEPLOY_PIPELINE_NAME $PROJECT_NAME`
RESP=$?
if [ "$RESP" -ne 0 ]
then
  echo "Problem getting ocid for deploy pipeline $DEPLOY_PIPELINE_NAME in project $PROJECT_NAME, unable to continue"
  exit $RESP
fi

cd $COMMON_DIR/devops

echo "Setting deploy pipeline paraps"
DEPLOY_PARAM_EXTERNAL_IP=`bash ./builders/build-pipeline-parameter.sh "EXTERNAL_IP" "$EXTERNAL_IP" "ingress controller external ip"`
DEPLOY_PARAM_NAMESPACE=`bash ./builders/build-pipeline-parameter.sh "KUBERNETES_NAMESPACE" "$NAMESPACE" "OKE Deployment namespace"`
DEPLOY_PARAMS_LIST=`bash ../build-items.sh "$DEPLOY_PARAM_EXTERNAL_IP" "$DEPLOY_PARAM_NAMESPACE"`


./deploy-pipeline-params-setup.sh "$DEPLOY_PIPELINE_NAME" "$PROJECT_NAME" "$BUILD_PARAMS_LIST"

echo "Adding start deployment stage to build pipeline"
cd $COMMON_DIR/devops
BUILD_TRIGGER_DEPLOYMENT_STAGE_PREDECESSOR=`bash ./builders/build-stage-predecessor.sh "$BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_OCID"`
BUILD_TRIGGER_DEPLOYMENT_STAGE_PREDECESSOR_ARRAY=`bash ../build-items-array.sh "$BUILD_TRIGGER_DEPLOYMENT_STAGE_PREDECESSOR"`

bash ./build-stage-trigger-deployment.sh "$BUILD_STAGE_TRIGGER_DEPLPOY_NAME" "$BUILD_PIPELINE_NAME" "$PROJECT_NAME" "$DEPLOY_PIPELINE_NAME" "$BUILD_TRIGGER_DEPLOYMENT_STAGE_PREDECESSOR_ARRAY" "$BUILD_STAGE_TRIGGER_DEPLPOY_DESCRIPTION" 

echo "Creating trigger on git repo"
cd $COMMON_DIR/devops 
bash ./trigger-on-devops-repo-setup.sh "$TRIGGER_ON_GIT_PUSH_NAME" "$PROJECT_NAME" "$CODE_REPO_NAME" "$GIT_BRANCH_NAME" "$BUILD_PIPELINE_NAME" "$TRIGGER_ON_GIT_PUSH_DESCRIPTION"
