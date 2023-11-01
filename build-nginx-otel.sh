#!/bin/bash

githubRepoOwner=$1
nginxVersion=$2
otelModuleVersion=$3

nginxOtelImageTag=nginx-otel:${nginxVersion}-${otelModuleVersion}
ghcrNginxOtelImageTag=ghcr.io/${githubRepoOwner}/${nginxOtelImageTag}

docker manifest inspect ${ghcrNginxOtelImageTag}
if [ $? -ne 0 ]; then
    docker build \
        --build-arg NGINX_VERSION=${nginxVersion} \
        --build-arg OTEL_MODULE_VERSION=${otelModuleVersion} \
        -t ${nginxOtelImageTag} --file gateway/Dockerfile-nginx-otel gateway/
    docker tag ${nginxOtelImageTag} ${ghcrNginxOtelImageTag}
    docker push ${ghcrNginxOtelImageTag}
else
    docker pull ${ghcrNginxOtelImageTag}
    docker tag ${ghcrNginxOtelImageTag} ${nginxOtelImageTag}
fi
