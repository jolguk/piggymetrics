#!/usr/bin/env bash
################################################
# This script is invoked by a human who:
# - has invoked the setup-actions-env.sh script
#
# This script removes the secrets and variables created in setup-actions-env.sh.
#
# This script should be invoked in the root directory of the github repo that was cloned, e.g.:
# ```
# cd <path-to-local-clone-of-the-github-repo>
# ./.github/tear-down-actions-env.sh
# ``` 
#
# Script design taken from https://github.com/microsoft/NubesGen.
#
################################################


set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

setup_colors

read -r -p "Enter disambiguation prefix: " DISAMBIG_PREFIX
read -r -p "Enter owner/reponame (blank for upsteam of current fork): " OWNER_REPONAME

if [ -z "${OWNER_REPONAME}" ] ; then
    GH_FLAGS=""
else
    GH_FLAGS="--repo ${OWNER_REPONAME}"
fi

SERVICE_PRINCIPAL_NAME=${DISAMBIG_PREFIX}sp

# Delete app registration and its service principal together
msg "${GREEN}(1/3) Delete service principal ${SERVICE_PRINCIPAL_NAME}"
APP_ID_ARRAY=$(az ad app list --display-name ${SERVICE_PRINCIPAL_NAME} --query "[].appId") || true
# Remove whitespace
APP_ID_ARRAY=$(echo ${APP_ID_ARRAY} | xargs) || true
APP_ID_ARRAY=${APP_ID_ARRAY//[/}
APP_ID=${APP_ID_ARRAY//]/}
az ad app delete --id ${APP_ID} || true

# Check GitHub CLI status
msg "${GREEN}(2/3) Checking GitHub CLI status...${NOFORMAT}"
USE_GITHUB_CLI=false
{
  gh auth status && USE_GITHUB_CLI=true && msg "${YELLOW}GitHub CLI is installed and configured!"
} || {
  msg "${YELLOW}Cannot use the GitHub CLI. ${GREEN}No worries! ${YELLOW}We'll remove the GitHub secrets and variables manually."
  USE_GITHUB_CLI=false
}

msg "${GREEN}(3/3) Removing secrets and variables...${NOFORMAT}"
if $USE_GITHUB_CLI; then
  {
    msg "${GREEN}Using the GitHub CLI to remove secrets and variables.${NOFORMAT}"
    gh ${GH_FLAGS} secret remove AZURE_CREDENTIALS
    gh ${GH_FLAGS} secret remove KEYSTORE_PASSWORD
    gh ${GH_FLAGS} secret remove MONGODB_USER
    gh ${GH_FLAGS} secret remove MONGODB_PASSWORD
    gh ${GH_FLAGS} variable remove RESOURCE_GROUP_NAME
    gh ${GH_FLAGS} variable remove AKS_CLUSTER_NAME
    gh ${GH_FLAGS} variable remove ACR_NAME
    gh ${GH_FLAGS} variable remove NAMESPACE_NAME
    gh ${GH_FLAGS} variable remove NGINX_VERSION
    gh ${GH_FLAGS} variable remove OTEL_MODULE_VERSION
    msg "${GREEN}Secrets and variables removed"
  } || {
    USE_GITHUB_CLI=false
  }
fi
if [ $USE_GITHUB_CLI == false ]; then
  msg "${NOFORMAT}======================MANUAL REMOVAL======================================"
  msg "${GREEN}Using your Web browser to remove secrets and variables..."
  msg "${NOFORMAT}Go to the GitHub repository you want to configure."
  msg "${NOFORMAT}In the \"Settings > Secrets and variables > Actions\", go to the \"Secrets\" tab and remove the following secrets:"
  msg "(in ${YELLOW}yellow the secret name)"
  msg "${YELLOW}\"AZURE_CREDENTIALS\""
  msg "${YELLOW}\"KEYSTORE_PASSWORD\""
  msg "${YELLOW}\"MONGODB_USER\""
  msg "${YELLOW}\"MONGODB_PASSWORD\""
  msg "${NOFORMAT}Go to the \"Variables\" tab and remove the following variables:"
  msg "(in ${YELLOW}yellow the variable name)"
  msg "${YELLOW}\"RESOURCE_GROUP_NAME\""
  msg "${YELLOW}\"AKS_CLUSTER_NAME\""
  msg "${YELLOW}\"ACR_NAME\""
  msg "${YELLOW}\"NAMESPACE_NAME\""
  msg "${YELLOW}\"NGINX_VERSION\""
  msg "${YELLOW}\"OTEL_MODULE_VERSION\""
  msg "${NOFORMAT}========================================================================"
fi
