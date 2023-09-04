TOPIC_NAME="$USER_INITIALS""DevOpsTopic"
PROJECT_NAME="$USER_INITIALS""DevOpsProject"
LOG_GROUP_NAME="Default_Group"
LOG_GROUP_DESCRIPTION="Auto created log group for all users in the compartment"
LOG_NAME="$PROJECT_NAME""_all"
CODE_REPO_NAME="cloudnative-helidon-storefront"
HOST_SECRET_NAME="OCIR_HOST"
NAMESPACE_SECRET_NAME="OCIR_STORAGE_NAMESPACE"
CODE_BASE="$HOME/cloudnative-helidon-storefront"
SOURCE_BUILD_SPEC="$CODE_BASE/helidon-storefront-full/yaml/build/build_spec.yaml"
WORKING_BUILD_SPEC="$CODE_BASE/build_spec.yaml"
STATUS_RESOURCE="$CODE_BASE/helidon-storefront-full/src/main/java/com/oracle/labs/helidon/storefront/resources/StatusResource.java"
BUILD_PIPELINE_NAME="BuildStorefront"
OCIR_REPO_NAME="$USER_INITIALS""devops/storefront"
ARTIFACT_REPO_NAME="$USER_INITIALS""DevOps"
BUILD_STAGE_RUNNER_NAME=buildstorefront
GIT_BRANCH_NAME="my-lab-branch"

STATUS_VERSION_ORIGIONAL='1.0.0'
STATUS_VERSION_UPDATED='1.0.1'
STATUS_VERSION_FINAL='3.14.59'

DEVOPS_DEPLOY_ENV_NAME="$USER_INITIALS""_OKE"

DEPLOY_PIPELINE_NAME="DeployStorefront"

PARAM_BUILD_INITIALS_NAME="YOUR_INITIALS"
PARAM_BUILD_INITIALS_DESCRIPTION="Your initials"

PARAM_DEPLOY_EXTERNAL_IP_NAME='EXTERNAL_IP'
PARAM_DEPLOY_EXTERNAL_IP_DESCRIPTION='ingress controller external ip'
PARAM_DEPLOY_NAMESPACE_NAME='KUBERNETES_NAMESPACE'
PARAM_DEPLOY_NAMESPACE_DESCRIPTION='OKE Deployment namespace'

ARTIFACT_STOREFRONT_SERVICE_NAME='StorefrontServiceYAML'
ARTIFACT_STOREFRONT_SERVICE_PATH='serviceStorefront.yaml'
ARTIFACT_STOREFRONT_SERVICE_VERSION='${STOREFRONT_VERSION}'
ARTIFACT_STOREFRONT_SERVICE_BUILD_SPEC_EXPORT_NAME='service_yaml'
ARTIFACT_STOREFRONT_DEPLOYMENT_NAME='StorefrontDeploymentYAML'
ARTIFACT_STOREFRONT_DEPLOYMENT_PATH='storefront-deployment.yaml'
ARTIFACT_STOREFRONT_DEPLOYMENT_VERSION='${STOREFRONT_VERSION}'
ARTIFACT_STOREFRONT_DEPLOYMENT_BUILD_SPEC_EXPORT_NAME='deployment_yaml'
ARTIFACT_STOREFRONT_INGRESS_NAME='StorefrontIngressRuleYAML'
ARTIFACT_STOREFRONT_INGRESS_PATH='ingressStorefrontRules.yaml'
ARTIFACT_STOREFRONT_INGRESS_VERSION='${STOREFRONT_VERSION}'
ARTIFACT_STOREFRONT_INGRESS_BUILD_SPEC_EXPORT_NAME='ingressRules_yaml'
ARTIFACT_STOREFRONT_OCIR_NAME='StorefrontContainer'
ARTIFACT_STOREFRONT_OCIR_PATH='${OCIR_HOST}/${OCIR_STORAGE_NAMESPACE}/${YOUR_INITIALS}devops/storefront:${STOREFRONT_VERSION}'
ARTIFACT_STOREFRONT_OCIR_BUILD_SPEC_EXPORT_NAME='storefront_container_image'
BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_NAME="UploadStorefrontArtifacts"
BUILD_ARTIFACT_TO_DEPLOYMENT_STAGE_DESCRIPTION="Upload artifacts to the registries"

DEPLOY_STAGE_STOREFRONT_DEPLOYMENT_NAME='StorefrontDeployDeployment'
DEPLOY_STAGE_STOREFRONT_DEPLOYMENT_DESCRIPTION='Applies the storefront deployment to the cluster'
DEPLOY_STAGE_STOREFRONT_SERVICE_NAME='StorefrontServiceDeployment'
DEPLOY_STAGE_STOREFRONT_SERCICE_DESCRIPTION='Applies the storefront service to the cluster'
DEPLOY_STAGE_STOREFRONT_INGRESS_NAME='StorefrontIngressDeployment'
DEPLOY_STAGE_STOREFRONT_INGREESS_DESCRIPTION='Applies the storefront ingress to the cluster'

BUILD_STAGE_TRIGGER_DEPLPOY_NAME='StartStorefrontDeployment'
BUILD_STAGE_TRIGGER_DEPLPOY_DESCRIPTION='Trigger storefront deployment pipeline after build'

TRIGGER_ON_GIT_PUSH_NAME='StorefrontTrigger'
TRIGGER_ON_GIT_PUSH_DESCRIPTION='triggers the build of the storefront'
