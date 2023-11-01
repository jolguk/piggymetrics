#!/bin/bash

source util.sh

resourceGroupName=$1
aksClusterName=$2
registryName=$3
imageTag=$4
keystorePassword=$5
namespace=$6
nginxVersion=$7
otelModuleVersion=$8

mvn clean install -Dliberty.var.keystore.pass=${keystorePassword}

registryServer=$(az acr show -n ${registryName} --query 'loginServer' -o tsv)
docker build -t ${registryServer}/auth-service:${imageTag} auth-service/
docker build -t ${registryServer}/statistics-service:${imageTag} statistics-service/
docker build -t ${registryServer}/account-service:${imageTag} account-service/
docker build --build-arg NGINX_VERSION=${nginxVersion} --build-arg OTEL_MODULE_VERSION=${otelModuleVersion} -t ${registryServer}/gateway:${imageTag} gateway/

az acr login -n ${registryName}

docker push ${registryServer}/auth-service:${imageTag}
docker push ${registryServer}/statistics-service:${imageTag}
docker push ${registryServer}/account-service:${imageTag}
docker push ${registryServer}/gateway:${imageTag}

az aks get-credentials -g ${resourceGroupName} -n ${aksClusterName} --overwrite-existing

# Update deployment image
kubectl set image deployment/auth auth=${registryServer}/auth-service:${imageTag} -n ${namespace}
kubectl set image deployment/statistics statistics=${registryServer}/statistics-service:${imageTag} -n ${namespace}
kubectl set image deployment/account account=${registryServer}/account-service:${imageTag} -n ${namespace}
kubectl set image deployment/gateway gateway=${registryServer}/gateway:${imageTag} -n ${namespace}

# Wait for deployment rollout to finish
kubectl rollout status deployment/auth -n ${namespace}
kubectl rollout status deployment/statistics -n ${namespace}
kubectl rollout status deployment/account -n ${namespace}
kubectl rollout status deployment/gateway -n ${namespace}

# Doublce check if deployment succeeded
wait_deployment_complete auth ${namespace}
wait_deployment_complete statistics ${namespace}
wait_deployment_complete account ${namespace}
wait_deployment_complete gateway ${namespace}
