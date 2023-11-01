#!/bin/bash

source util.sh

resourceGroupName=$1
aksClusterName=$2
registryName=$3
imageTag=$4
mongoDbUsername=$5
mongoDbPassword=$6
keystorePassword=$7
namespace=$8

az aks get-credentials -g $resourceGroupName -n $aksClusterName --overwrite-existing

registryServer=$(az acr show -n ${registryName} --query 'loginServer' -o tsv)
export AUTH_IMAGE=${registryServer}/auth-service:${imageTag}
export STATISTICS_IMAGE=${registryServer}/statistics-service:${imageTag}
export ACCOUNT_IMAGE=${registryServer}/account-service:${imageTag}
export GATEWAY_IMAGE=${registryServer}/gateway:${imageTag}

export NAMESPACE=${namespace}
kubectl create namespace ${NAMESPACE}

# Install prometheus and grafana
envsubst < deployment/prometheus-rbac.yaml | kubectl apply --namespace=${NAMESPACE} -f -
kubectl apply --namespace=${NAMESPACE} -f deployment/prometheus-deploy.yaml
kubectl apply --namespace=${NAMESPACE} -f deployment/grafana.yaml
wait_deployment_complete prometheus ${NAMESPACE}
wait_deployment_complete grafana ${NAMESPACE}

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
wait_deployment_complete ingress-nginx-controller ingress-nginx

# Install cert-manager
CERT_MANAGER_VERSION=v1.11.2
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml
wait_deployment_complete cert-manager cert-manager
wait_deployment_complete cert-manager-cainjector cert-manager
wait_deployment_complete cert-manager-webhook cert-manager

# Install Jaeger
kubectl create namespace observability
kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.49.0/jaeger-operator.yaml -n observability
wait_deployment_complete jaeger-operator observability
kubectl apply --namespace=${NAMESPACE} -f deployment/jaeger.yaml
wait_deployment_complete jaeger ${NAMESPACE}
kubectl get ingress jaeger-query --namespace=${NAMESPACE}
while [ $? -ne 0 ]
do
  sleep 10
  kubectl get ingress jaeger-query --namespace=${NAMESPACE}
done
kubectl delete ingress jaeger-query --namespace=${NAMESPACE}
kubectl apply --namespace=${NAMESPACE} -f deployment/jaeger-ingress.yaml

# Install Elasticsearch and Kibana
kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/2.9.0/operator.yaml
kubectl apply --namespace=${NAMESPACE} -f deployment/elasticsearch.yaml
kubectl apply --namespace=${NAMESPACE} -f deployment/kibana.yaml
# elastic-system/elastic-operator and piggymetrics/quickstart-es-default are statefulsets which are dependences of Kibana
wait_deployment_complete quickstart-kb ${NAMESPACE}

# Create secret and config map
export ELASTICSEARCH_PASSWORD=$(kubectl get secret --namespace=${NAMESPACE} quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
export ELASTICSEARCH_USERNAME=elastic
export ELASTICSEARCH_HOST=quickstart-es-http
export ELASTICSEARCH_PORT=9200
export MONGODB_USER=${mongoDbUsername}
export MONGODB_PASSWORD=${mongoDbPassword}
export KEYSTORE_PASSWORD=${keystorePassword}
envsubst < deployment/secret.yaml | kubectl apply --namespace=${NAMESPACE} -f -
envsubst < deployment/configmap.yaml | kubectl apply --namespace=${NAMESPACE} -f -

# Install MongoDB
kubectl apply --namespace=${NAMESPACE} -f deployment/mongo.yaml
wait_deployment_complete mongo ${NAMESPACE}

# Deploy piggymetrics app with filebeat
kubectl apply --namespace=${NAMESPACE} -f deployment/filebeat.yaml
envsubst < deployment/piggymetrics.yaml | kubectl apply --namespace=${NAMESPACE} -f -
wait_deployment_complete auth ${NAMESPACE}
wait_deployment_complete statistics ${NAMESPACE}
wait_deployment_complete account ${NAMESPACE}
wait_deployment_complete gateway ${NAMESPACE}
wait_deployment_complete nginx-prometheus-exporter ${NAMESPACE}

# Wait until all services' endpoints are available
wait_service_available gateway ${NAMESPACE} 1
wait_service_available grafana ${NAMESPACE} 0
wait_service_available quickstart-kb-http ${NAMESPACE} 0
wait_ingress_available jaeger-query ${NAMESPACE}
