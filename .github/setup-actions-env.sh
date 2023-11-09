#!/usr/bin/env bash
################################################
# This script is invoked by a human who:
# - can create GitHub Actions secrets and variables in the github repo from which this file was cloned.
# - has the gh client >= 2.32.1 installed.
#
# This script initializes the repo from which this file was cloned
# with the necessary secrets and variables to run the workflows.
# 
# This script should be invoked in the root directory of the github repo that was cloned, e.g.:
# ```
# cd <path-to-local-clone-of-the-github-repo>
# ./.github/setup-actions-env.sh
# ``` 
#
# Script design taken from https://github.com/microsoft/NubesGen.
#
################################################

################################################
# Set environment variables - the main variables you might want to configure.
#
# Prefix to disambiguate names
DISAMBIG_PREFIX=
# Owner/reponame, e.g., <USER_NAME>/piggymetrics
OWNER_REPONAME=
# Password for keystore
KEYSTORE_PASSWORD=
# User name for MongoDB
MONGODB_USER=
# Password for MongoDB
MONGODB_PASSWORD=
# Resource group name where the AKS cluster and ACR will be deployed or have been deployed
RESOURCE_GROUP_NAME=
# AKS cluster name
AKS_CLUSTER_NAME=
# ACR name
ACR_NAME=
# Namespace name where the application will be deployed or has been deployed, default is "piggymetrics"
NAMESPACE_NAME=
# NGINX version, default is "1.25.2"
NGINX_VERSION=
# OpenTelemetry module version, default is "0.1.0"
OTEL_MODULE_VERSION=

# End set environment variables
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

read -r -p "Enter a disambiguation prefix (try initials with a sequence number, such as ejb01): " DISAMBIG_PREFIX

if [ "$DISAMBIG_PREFIX" == '' ] ; then
    msg "${RED}You must enter a disambiguation prefix."
    exit 1;
fi

DISAMBIG_PREFIX=${DISAMBIG_PREFIX}`date +%m%d`

# get OWNER_REPONAME if not set at the beginning of this file
if [ "$OWNER_REPONAME" == '' ] ; then
    read -r -p "Enter owner/reponame (blank for upsteam of current fork): " OWNER_REPONAME
fi

if [ -z "${OWNER_REPONAME}" ] ; then
    GH_FLAGS=""
else
    GH_FLAGS="--repo ${OWNER_REPONAME}"
fi

# get KEYSTORE_PASSWORD if not set at the beginning of this file
if [ "$KEYSTORE_PASSWORD" == '' ] ; then
    read -r -p "Enter password for keystore: " KEYSTORE_PASSWORD
fi

# get MONGODB_USER if not set at the beginning of this file
if [ "$MONGODB_USER" == '' ] ; then
    read -r -p "Enter username for MongoDB: " MONGODB_USER
fi

# get MONGODB_PASSWORD if not set at the beginning of this file
if [ "$MONGODB_PASSWORD" == '' ] ; then
    read -r -p "Enter password for MongoDB: " MONGODB_PASSWORD
fi

# get RESOURCE_GROUP_NAME if not set at the beginning of this file
if [ "$RESOURCE_GROUP_NAME" == '' ] ; then
    read -r -p "Enter resource group name where the AKS cluster and ACR will be deployed or have been deployed: " RESOURCE_GROUP_NAME
fi

# get AKS_CLUSTER_NAME if not set at the beginning of this file
if [ "$AKS_CLUSTER_NAME" == '' ] ; then
    read -r -p "Enter AKS cluster name: " AKS_CLUSTER_NAME
fi

# get ACR_NAME if not set at the beginning of this file
if [ "$ACR_NAME" == '' ] ; then
    read -r -p "Enter ACR name: " ACR_NAME
fi

# Optional: get NAMESPACE_NAME if not set at the beginning of this file
if [ "$NAMESPACE_NAME" == '' ] ; then
    read -r -p "[Optional] Enter namespace name where the application will be deployed or has been deployed, or press 'Enter' to use default value 'piggymetrics': " NAMESPACE_NAME
fi
if [ -z "${NAMESPACE_NAME}" ] ; then
    NAMESPACE_NAME=piggymetrics
fi

# Optional: get NGINX_VERSION if not set at the beginning of this file
if [ "$NGINX_VERSION" == '' ] ; then
    read -r -p "[Optional] Enter NGINX version, or press 'Enter' to use default value '1.25.2': " NGINX_VERSION
fi
if [ -z "${NGINX_VERSION}" ] ; then
    NGINX_VERSION=1.25.2
fi

# Optional: get OTEL_MODULE_VERSION if not set at the beginning of this file
if [ "$OTEL_MODULE_VERSION" == '' ] ; then
    read -r -p "[Optional] Enter OpenTelemetry module version, or press 'Enter' to use default value '0.1.0': " OTEL_MODULE_VERSION
fi
if [ -z "${OTEL_MODULE_VERSION}" ] ; then
    OTEL_MODULE_VERSION=0.1.0
fi

SERVICE_PRINCIPAL_NAME=${DISAMBIG_PREFIX}sp

# Check AZ CLI status
msg "${GREEN}(1/4) Checking Azure CLI status...${NOFORMAT}"
{
  az > /dev/null
} || {
  msg "${RED}Azure CLI is not installed."
  msg "${GREEN}Go to https://aka.ms/nubesgen-install-az-cli to install Azure CLI."
  exit 1;
}
{
  az account show > /dev/null
} || {
  msg "${RED}You are not authenticated with Azure CLI."
  msg "${GREEN}Run \"az login\" to authenticate."
  exit 1;
}

msg "${YELLOW}Azure CLI is installed and configured!"

# Check GitHub CLI status
msg "${GREEN}(2/4) Checking GitHub CLI status...${NOFORMAT}"
USE_GITHUB_CLI=false
{
  gh auth status && USE_GITHUB_CLI=true && msg "${YELLOW}GitHub CLI is installed and configured!"
} || {
  msg "${YELLOW}Cannot use the GitHub CLI. ${GREEN}No worries! ${YELLOW}We'll set up the GitHub secrets and variables manually."
  USE_GITHUB_CLI=false
}

# Create service principal with Contributor role in the subscription
msg "${GREEN}(3/4) Create service principal ${SERVICE_PRINCIPAL_NAME}"
SUBSCRIPTION_ID=$(az account show --query id --output tsv --only-show-errors)
# Explicitely disable line wrapping for non MacOS 
w0=-w0
if [[ $OSTYPE == 'darwin'* ]]; then
  w0=
fi
SERVICE_PRINCIPAL=$(az ad sp create-for-rbac --name ${SERVICE_PRINCIPAL_NAME} --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}" --sdk-auth --only-show-errors | base64 $w0)
msg "${YELLOW}\"Write down the DISAMBIG_PREFIX appended with date info below, which is required by script tear-down-actions-env.sh\""
msg "${GREEN}${DISAMBIG_PREFIX}"

# Assign User Access Administrator role in the subscription
SP_ID=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query [0].id -o tsv)
az role assignment create --assignee ${SP_ID} --role "User Access Administrator"

# Create GitHub action secrets and variables
AZURE_CREDENTIALS=$(echo $SERVICE_PRINCIPAL | base64 -d)

msg "${GREEN}(4/4) Create secrets and variables in GitHub"
if $USE_GITHUB_CLI; then
  {
    msg "${GREEN}Using the GitHub CLI to set secrets and variables.${NOFORMAT}"
    gh ${GH_FLAGS} secret set AZURE_CREDENTIALS -b"${AZURE_CREDENTIALS}"
    msg "${YELLOW}\"AZURE_CREDENTIALS\""
    msg "${GREEN}${AZURE_CREDENTIALS}"
    gh ${GH_FLAGS} secret set KEYSTORE_PASSWORD -b"${KEYSTORE_PASSWORD}"
    gh ${GH_FLAGS} secret set MONGODB_USER -b"${MONGODB_USER}"
    gh ${GH_FLAGS} secret set MONGODB_PASSWORD -b"${MONGODB_PASSWORD}"
    gh ${GH_FLAGS} variable set RESOURCE_GROUP_NAME -b"${RESOURCE_GROUP_NAME}"
    gh ${GH_FLAGS} variable set AKS_CLUSTER_NAME -b"${AKS_CLUSTER_NAME}"
    gh ${GH_FLAGS} variable set ACR_NAME -b"${ACR_NAME}"
    gh ${GH_FLAGS} variable set NAMESPACE_NAME -b"${NAMESPACE_NAME}"
    gh ${GH_FLAGS} variable set NGINX_VERSION -b"${NGINX_VERSION}"
    gh ${GH_FLAGS} variable set OTEL_MODULE_VERSION -b"${OTEL_MODULE_VERSION}"
    msg "${GREEN}Secrets and variables configured"
  } || {
    USE_GITHUB_CLI=false
  }
fi
if [ $USE_GITHUB_CLI == false ]; then
  msg "${NOFORMAT}======================MANUAL SETUP======================================"
  msg "${GREEN}Using your Web browser to set up secrets and variables..."
  msg "${NOFORMAT}Go to the GitHub repository you want to configure."
  msg "${NOFORMAT}In the \"Settings > Secrets and variables > Actions\", go to the \"Secrets\" tab and add the following secrets:"
  msg "(in ${YELLOW}yellow the secret name and${NOFORMAT} in ${GREEN}green the secret value)"
  msg "${YELLOW}\"AZURE_CREDENTIALS\""
  msg "${GREEN}${AZURE_CREDENTIALS}"
  msg "${YELLOW}\"KEYSTORE_PASSWORD\""
  msg "${GREEN}${KEYSTORE_PASSWORD}"
  msg "${YELLOW}\"MONGODB_USER\""
  msg "${GREEN}${MONGODB_USER}"
  msg "${YELLOW}\"MONGODB_PASSWORD\""
  msg "${GREEN}${MONGODB_PASSWORD}"
  msg "${NOFORMAT}Go to the \"Variables\" tab and add the following variables:"
  msg "(in ${YELLOW}yellow the variable name and${NOFORMAT} in ${GREEN}green the variable value)"
  msg "${YELLOW}\"RESOURCE_GROUP_NAME\""
  msg "${GREEN}${RESOURCE_GROUP_NAME}"
  msg "${YELLOW}\"AKS_CLUSTER_NAME\""
  msg "${GREEN}${AKS_CLUSTER_NAME}"
  msg "${YELLOW}\"ACR_NAME\""
  msg "${GREEN}${ACR_NAME}"
  msg "${YELLOW}\"NAMESPACE_NAME\""
  msg "${GREEN}${NAMESPACE_NAME}"
  msg "${YELLOW}\"NGINX_VERSION\""
  msg "${GREEN}${NGINX_VERSION}"
  msg "${YELLOW}\"OTEL_MODULE_VERSION\""
  msg "${GREEN}${OTEL_MODULE_VERSION}"
  msg "${NOFORMAT}========================================================================"
fi
