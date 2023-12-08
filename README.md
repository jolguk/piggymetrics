# Piggy Metrics on Open Liberty

NOTE: For original PiggyMetrics please see the branch [Azure](https://github.com/Azure-Samples/piggymetrics/tree/Azure).

## Description

It's a demo application for Open Liberty MicroProfile, which references the following major open-source projects and guides:

- [Open Liberty guides](https://openliberty.io/guides/): The quickest way to learn all things Open Liberty, and beyond!
- [`piggymetrics`](https://github.com/Azure-Samples/piggymetrics): front-end, REST APIs definition and business logics 
- [`sample-acmegifts`](https://github.com/OpenLiberty/sample-acmegifts): architecture and OpenLiberty ways to implement microservices
- [`liberty-mongodb`](https://github.com/JNOSQL/demos-ee/tree/main/liberty-mongodb): MicroProfile Open Liberty with MongoDB sample
- [`openliberty-config-example`](https://github.com/sdaschner/openliberty-config-example/tree/prometheus-k8s): use Prometheus to collect metrics data of microservices and get them visualized/monitored in Grafana dashboard

Note: The notification service from the original [`piggymetrics`](https://github.com/Azure-Samples/piggymetrics) project is not ported yet, due to the time limitation. This will be implemented when time permits in the future.

## Technologies used

- [Eclipse MicroProfile 6.0](https://microprofile.io/compatible/6-0/)
  - Config 3.0
  - Fault Tolerance 4.0
  - Health 4.0
  - Metrics 5.0
  - JWT Authentication 2.1
  - Rest Client 3.0
  - Telemetry 1.0
  - Open API 3.1
- [Jakarta EE Core Profile 10](https://jakarta.ee/specifications/coreprofile/10/)
  - Jakarta Annotations 2.1
  - Jakarta CDI 4.0
  - Jakarta JSON Processing 2.1
  - Jakarta JSON Binding 3.0
  - Jakarta RESTful Web Services 3.1
- [Eclipse JNoSQL](https://github.com/eclipse/jnosql)
- [Jaeger for distributed tracing](https://www.jaegertracing.io/)
- [Prometheus/Grafana for metric collection/visualization](https://prometheus.io/docs/visualization/grafana/)
- [ELK for log aggregation & analysis](https://www.elastic.co/)
- [Nginx for serving static contents and reverse proxy](https://www.nginx.com/)

## Prerequisites

To successfully build and run the application, you need to satisfy the following prerequisites:

- Install Git
- Install JDK
- Install Maven
- Install Docker Desktop
- Register an [Azure subscription](https://azure.microsoft.com/)
- Install [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli?view=azure-cli-latest)
- Install [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Install `envsubst` utility for replacing environment variables in template files
- Install `keytool` and `openssl` utilities for generating self-signed certificates

## Run in local

Mongo DB is used as database for our demo services, start it as a Docker container. Be sure to replace the placeholder `<your-db-username>` and `<your-db-password>` with your database username and password before running the commands.

```bash
docker run --rm --name mongo \
  -e MONGO_INITDB_ROOT_USERNAME=<your-db-username> \
  -e MONGO_INITDB_ROOT_PASSWORD=<your-db-password> \
  -p 27017:27017 \
  mongo:latest
```

Jaeger is used as distributed tracing platform for our demo services. Open a new terminal and start it as a Docker container.

```bash
docker run --rm --name jaeger \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

There are multiple maven projects in the repo, open a new terminal to run the following commands to clone the repo and build all projects. Be sure to replace the placeholder `<your-keystore-password>` with your keystore password.

```bash
# Clone the repo
git clone https://github.com/Azure-Samples/piggymetrics.git
cd piggymetrics
git checkout openliberty

# Build projects
mvn clean install -Dliberty.var.keystore.pass=<your-keystore-password>
```

Open a new terminal to start PiggyMetrics `auth-service`. Be sure to replace the placeholder `<your-keystore-password>`, `<your-db-username>` and `<your-db-password>` with your keystore password, your database username and password.

```bash
cd piggymetrics/auth-service
export JNOSQL_MONGODB_USER=<your-db-username>
export JNOSQL_MONGODB_PASSWORD=<your-db-password>
mvn liberty:run -Dliberty.var.keystore.pass=<your-keystore-password>
```

Open a new terminal to start PiggyMetrics `statistics-service`. Be sure to replace the placeholder `<your-keystore-password>`, `<your-db-username>` and `<your-db-password>` with your keystore password, your database username and password.

```bash
cd piggymetrics/statistics-service
export JNOSQL_MONGODB_USER=<your-db-username>
export JNOSQL_MONGODB_PASSWORD=<your-db-password>
mvn liberty:run -Dliberty.var.keystore.pass=<your-keystore-password>
```

Open a new terminal to start PiggyMetrics `account-service`. Be sure to replace the placeholder `<your-keystore-password>`, `<your-db-username>` and `<your-db-password>` with your keystore password, your database username and password.

```bash
cd piggymetrics/account-service
export JNOSQL_MONGODB_USER=<your-db-username>
export JNOSQL_MONGODB_PASSWORD=<your-db-password>
mvn liberty:run -Dliberty.var.keystore.pass=<your-keystore-password>
```

Open a new terminal to start PiggyMetrics `gateway`.

* Follow instructions from [NGINX Native OpenTelemetry (OTel) Module](https://github.com/nginxinc/nginx-otel) to build and install `ngx_otel_module` dynamic module and NGINX on Ubuntu.
* Verify installation of NGINX by running:

  ```bash
  sudo nginx
  curl -I localhost
  sudo nginx -s stop
  ```

* Run following commands to start NGINX server which serves front-end web app and proxies API requests to back-end services.

  ```bash
  cd piggymetrics/gateway
  sudo cp -f nginx/certfile.pem /etc/ssl/certfile.pem
  sudo cp -f nginx/keyfile.key /etc/ssl/keyfile.key
  sudo cp -rf src/main/webapp /usr/share/nginx/

  export JAEGER_URL=localhost:4317
  export AUTH_SERVICE_URL=http://localhost:9180
  export ACCOUNT_SERVICE_URL=http://localhost:9280
  export STATISTICS_SERVICE_URL=http://localhost:9380
  envsubst '${JAEGER_URL} ${AUTH_SERVICE_URL} ${ACCOUNT_SERVICE_URL} ${STATISTICS_SERVICE_URL}' < nginx/nginx.conf.template > nginx/nginx.conf
  # Test NGINX for custom configuration file
  sudo nginx -t -c $(pwd)/nginx/nginx.conf
  # Start NGINX with custom configuration file
  sudo nginx -c $(pwd)/nginx/nginx.conf
  # Monitor NGINX access log
  tail -f /var/log/nginx/access.log
  ```

After all containers and services are up and running, open the following URLs in your browser to play and test the demo app, reference section [Live demo](#live-demo) for more information.

* https://localhost:9443: PiggyMetrics web console
* http://localhost:16686: Jaeger web console

Press `Ctrl+C` in each terminal to stop each container/service instance once you complete the try. Run `sudo nginx -s stop` to stop NGINX server. 

## Run in Docker

Open a new terminal to build a Docker image for NGINX with OpenTelemetry module, which is a base image for PiggyMetrics `gateway` application image.

```bash
cd piggymetrics

export NGINX_VERSION=1.25.2
export OTEL_MODULE_VERSION=0.1.0
docker build \
  --build-arg NGINX_VERSION=${NGINX_VERSION} \
  --build-arg OTEL_MODULE_VERSION=${OTEL_MODULE_VERSION} \
  -t nginx-otel:${NGINX_VERSION}-${OTEL_MODULE_VERSION} --file gateway/Dockerfile-nginx-otel gateway/
```

Then open a new terminal to build the services into Docker images. Be sure to replace the placeholder `<your-keystore-password>` with your keystore password.

```bash
cd piggymetrics
mvn clean install -Dliberty.var.keystore.pass=<your-keystore-password>

docker build -t auth-service:1.0 auth-service/
docker build -t statistics-service:1.0 statistics-service/
docker build -t account-service:1.0 account-service/
docker build --build-arg NGINX_VERSION=${NGINX_VERSION} --build-arg OTEL_MODULE_VERSION=${OTEL_MODULE_VERSION} -t gateway:1.0 gateway/
```

Run these application images and dependent middleware services as Docker containers via `docker-compose`. Be sure to replace the placeholder `<your-keystore-password>`, `<your-elasticsearch-password>`, `<your-db-username>` and `<your-db-password>` with your keystore password, your elasticsearch password, your database username and password.

```bash
export MONGODB_USER=<your-db-username>
export MONGODB_PASSWORD=<your-db-password>
export KEYSTORE_PASSWORD=<your-keystore-password>
export ELASTIC_PASSWORD=<your-elasticsearch-password>
export IMAGE_TAG=1.0
docker-compose -f docker/docker-compose.yml up
```

After all containers are up and running, open the following URLs in your browser to play and test the demo app, reference section [Live demo](#live-demo) for more information.

* https://localhost:9443: PiggyMetrics web console
* http://localhost:16686: Jaeger web console
* http://localhost:3000: Grafana web console
* http://localhost:5601: Kibana web console (elastic / `<your-elasticsearch-password>`)

Once you complete the try, press `Ctrl+C` to stop all containers and run the following commands to remove all container.

```bash
docker-compose -f docker/docker-compose.yml down
```

## Run in Azure Kubernetes Service (AKS) cluster

The last step is to deploy and run the containerized applications on AKS. Create an AKS cluster and Azure Container Registry (ACR) first.

### Create AKS cluster & ACR instance

If you haven't signed into Azure CLI, run the following command to sign in:

```bash
az login
```

Run the following commands to create an ACR instance and an AKS cluster.

```bash
let "identifier=$RANDOM*$RANDOM"
export RESOURCE_GROUP_NAME=${identifier}rg
export CLUSTER_NAME=${identifier}aks
export REGISTRY_NAME=${identifier}acr

az group create -l eastus -n $RESOURCE_GROUP_NAME
az acr create -g $RESOURCE_GROUP_NAME -n $REGISTRY_NAME --sku Basic --admin-enabled
az aks create -g $RESOURCE_GROUP_NAME -n $CLUSTER_NAME --node-count 6 --enable-managed-identity --generate-ssh-keys --attach-acr $REGISTRY_NAME
```

### Push images to container registries

Run the following commands to push images to GitHub container registry and the ACR instance, which will be deployed to the AKS cluster later. Be sure to replace the placeholder `<your-github-username>` and `<your-github-personal-access-token>` with your GitHub username and personal access token.

```bash
export NGINX_VERSION=1.25.2
export OTEL_MODULE_VERSION=0.1.0
docker tag nginx-otel:${NGINX_VERSION}-${OTEL_MODULE_VERSION} \
  ghcr.io/<your-github-username>/nginx-otel:${NGINX_VERSION}-${OTEL_MODULE_VERSION}

docker login ghcr.io -u <your-github-username> -p <your-github-personal-access-token>
docker push ghcr.io/<your-github-username>/nginx-otel:${NGINX_VERSION}-${OTEL_MODULE_VERSION}

export REGISTRY_SERVER=$(az acr show -n $REGISTRY_NAME --query 'loginServer' -o tsv)

docker tag gateway:1.0 ${REGISTRY_SERVER}/gateway:1.0
docker tag auth-service:1.0 ${REGISTRY_SERVER}/auth-service:1.0
docker tag account-service:1.0 ${REGISTRY_SERVER}/account-service:1.0
docker tag statistics-service:1.0 ${REGISTRY_SERVER}/statistics-service:1.0

# Log into Azure Container Registry
az acr login -n ${REGISTRY_NAME}

docker push ${REGISTRY_SERVER}/gateway:1.0
docker push ${REGISTRY_SERVER}/auth-service:1.0
docker push ${REGISTRY_SERVER}/account-service:1.0
docker push ${REGISTRY_SERVER}/statistics-service:1.0
```

If you haven't built application images before, here is a utilty script which can build projects, containerize applications and push to container registries. 
Be sure to replace the placeholder `<your-github-username>`, `<your-github-personal-access-token>` `<your-keystore-password>` with your GitHub username, personal access token, and keystore password before running the following commands.

```bash
export NGINX_VERSION=1.25.2
export OTEL_MODULE_VERSION=0.1.0
docker login ghcr.io -u <your-github-username> -p <your-github-personal-access-token>
./build-nginx-otel.sh <your-github-username> ${NGINX_VERSION} ${OTEL_MODULE_VERSION}

export KEYSTORE_PASSWORD=<your-keystore-password>
export IMAGE_TAG=1.0
./build-piggymetrics.sh $KEYSTORE_PASSWORD $IMAGE_TAG ${NGINX_VERSION} ${OTEL_MODULE_VERSION} $REGISTRY_NAME
```

It's recommened that:

* Connecting your `piggymetrics` repository to the package/image `nginx-otel` you just pushed, reference [this link](https://docs.github.com/en/packages/learn-github-packages/connecting-a-repository-to-a-package#connecting-a-repository-to-a-user-scoped-package-on-github) for more information.
* Following instructions from [Configuring visibility of packages for your personal account](https://docs.github.com/en/packages/learn-github-packages/configuring-a-packages-access-control-and-visibility#configuring-visibility-of-packages-for-your-personal-account) to configure the visibility of package/image `nginx-otel` as **Public**, so it can be reused later.

### Deploy and run containerized applications on AKS

Once you prepared all images, you can deploy them to the AKS cluster.
Be sure to replace the placeholder `<your-keystore-password>`, `<your-db-username>` and `<your-db-password>` with your keystore password, your database username and password.

```bash
export IMAGE_TAG=1.0
export MONGODB_USER=<your-db-username>
export MONGODB_PASSWORD=<your-db-password>
export KEYSTORE_PASSWORD=<your-keystore-password>
export NAMESPACE=piggymetrics
./deploy.sh $RESOURCE_GROUP_NAME $CLUSTER_NAME $REGISTRY_NAME $IMAGE_TAG $MONGODB_USER $MONGODB_PASSWORD $KEYSTORE_PASSWORD $NAMESPACE
```

It will take a while to deploy and run the following services:

Middleware:

* Database:
  * Mongo DB
* Obserbility:
  * Tracing: Jaeger
  * Metrics: Prometheus / Grafana
  * Logs: Elastic / Kibana

PiggyMetrics services:

* Gateway (running on NGINX server)
* Auth
* Account
* Statistics

Once the script completes, you can run the following commands to get the endpoints and their login credentials.

```bash
export NAMESPACE=piggymetrics
export ELASTICSEARCH_PASSWORD=$(kubectl get secret --namespace=${NAMESPACE} quickstart-es-elastic-user -o=jsonpath='{.data.elastic}' | base64 --decode)
echo ""
echo "========================================"
echo ""
echo "gatewayEndpoint: https://$(kubectl get svc gateway -n ${NAMESPACE} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[1].port}')"
echo "jaegerEndpoint: http://$(kubectl get ingress jaeger-query -n ${NAMESPACE} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "grafanaEndpoint: http://$(kubectl get svc grafana -n ${NAMESPACE} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}'), initial username: admin, initial password: admin"
echo "kibanaEndpoint: https://$(kubectl get svc quickstart-kb-http -n ${NAMESPACE} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}'), username: elastic, password: ${ELASTICSEARCH_PASSWORD}"
echo ""
```

Open endpoints in your browser to play and test the demo app, reference section [Live demo](#live-demo) for more information.

### Live demo

See live demo video from [this link](./media/PiggyMetrics_on_Open_Liberty.mp4) to understand how to visit different web consoles, including PiggyMetrics web console, Jaeger web console, Grafana web console (import dashboards [Open Liberty - mpMetrics-5.0](https://grafana.com/grafana/dashboards/18599-open-liberty/) and [NGINX exporter](https://grafana.com/grafana/dashboards/12708-nginx/)) and Kibaba web console.

## Cleanup

Delete Piggy Metrics related resources deployed in AKS cluster:

```bash
kubectl delete namespace piggymetrics
kubectl delete namespace elastic-system
kubectl delete namespace observability
kubectl delete namespace cert-manager
kubectl delete namespace ingress-nginx
```

Delete everythging including the ACR & AKS:

```bash
az group delete -n $RESOURCE_GROUP_NAME --yes --no-wait
```
