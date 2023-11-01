#!/bin/bash

keyStorePass=$1
registryName=$2
imageTag=$3
nginxVersion=$4
otelModuleVersion=$5

mvn clean install -Dliberty.var.keystore.pass=${keyStorePass}

docker rmi gateway:${imageTag}
docker rmi auth-service:${imageTag}
docker rmi account-service:${imageTag}
docker rmi statistics-service:${imageTag}

docker build --build-arg NGINX_VERSION=${nginxVersion} --build-arg OTEL_MODULE_VERSION=${otelModuleVersion} -t gateway:${imageTag} gateway/
docker build -t auth-service:${imageTag} auth-service/
docker build -t account-service:${imageTag} account-service/
docker build -t statistics-service:${imageTag} statistics-service/

registryServer=$(az acr show -n ${registryName} --query 'loginServer' -o tsv)
docker rmi ${registryServer}/gateway:${imageTag}
docker rmi ${registryServer}/auth-service:${imageTag}
docker rmi ${registryServer}/account-service:${imageTag}
docker rmi ${registryServer}/statistics-service:${imageTag}

docker tag gateway:${imageTag} ${registryServer}/gateway:${imageTag}
docker tag auth-service:${imageTag} ${registryServer}/auth-service:${imageTag}
docker tag account-service:${imageTag} ${registryServer}/account-service:${imageTag}
docker tag statistics-service:${imageTag} ${registryServer}/statistics-service:${imageTag}

# Log into Azure Container Registry
az acr login -n ${registryName}

docker push ${registryServer}/gateway:${imageTag}
docker push ${registryServer}/auth-service:${imageTag}
docker push ${registryServer}/account-service:${imageTag}
docker push ${registryServer}/statistics-service:${imageTag}
