#!/bin/bash

MAX_RETRIES=299

wait_deployment_complete() {
    deploymentName=$1
    namespaceName=$2

    cnt=0
    kubectl get deployment ${deploymentName} -n ${namespaceName}
    while [ $? -ne 0 ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached."
            return 1
        fi
        cnt=$((cnt+1))

        echo "Unable to get the deployment ${deploymentName}, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 5
        kubectl get deployment ${deploymentName} -n ${namespaceName}
    done

    cnt=0
    read -r -a replicas <<< `kubectl get deployment ${deploymentName} -n ${namespaceName} -o=jsonpath='{.spec.replicas}{" "}{.status.readyReplicas}{" "}{.status.availableReplicas}{" "}{.status.updatedReplicas}{"\n"}'`
    while [[ ${#replicas[@]} -ne 4 || ${replicas[0]} != ${replicas[1]} || ${replicas[1]} != ${replicas[2]} || ${replicas[2]} != ${replicas[3]} ]]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached."
            return 1
        fi
        cnt=$((cnt+1))

        # Delete pods in ImagePullBackOff status
        podIds=`kubectl get pod -n ${namespaceName} | grep ImagePullBackOff | awk '{print $1}'`
        read -r -a podIds <<< `echo $podIds`
        for podId in "${podIds[@]}"
        do
            echo "Delete pod ${podId} in ImagePullBackOff status"
            kubectl delete pod ${podId} -n ${namespaceName}
        done

        sleep 5
        echo "Wait until the deployment ${deploymentName} completes, retry ${cnt} of ${MAX_RETRIES}..."
        read -r -a replicas <<< `kubectl get deployment ${deploymentName} -n ${namespaceName} -o=jsonpath='{.spec.replicas}{" "}{.status.readyReplicas}{" "}{.status.availableReplicas}{" "}{.status.updatedReplicas}{"\n"}'`
    done
    echo "Deployment ${deploymentName} completed."
}

wait_service_available() {
    serviceName=$1
    namespaceName=$2
    portIndex=$3

    cnt=0
    kubectl get svc ${serviceName} -n ${namespaceName}
    while [ $? -ne 0 ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached."
            return 1
        fi
        cnt=$((cnt+1))

        echo "Unable to get the service ${serviceName}, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 5
        kubectl get svc ${serviceName} -n ${namespaceName}
    done

    cnt=0
    appEndpoint=$(kubectl get svc ${serviceName} -n ${namespaceName} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports['${portIndex}'].port}')
    echo "Service ${serviceName} ip:port is ${appEndpoint}"
    while [[ $appEndpoint = :* ]] || [[ -z $appEndpoint ]]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            return 1
        fi
        cnt=$((cnt+1))

        sleep 5
        echo "Wait until the IP address and port of the service ${serviceName} are available, retry ${cnt} of ${MAX_RETRIES}..."
        appEndpoint=$(kubectl get svc ${serviceName} -n ${namespaceName} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports['${portIndex}'].port}')
        echo "Service ${serviceName} ip:port is ${appEndpoint}"
    done
}

wait_ingress_available() {
    ingressName=$1
    namespaceName=$2

    cnt=0
    kubectl get ingress ${ingressName} -n ${namespaceName}
    while [ $? -ne 0 ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            return 1
        fi
        cnt=$((cnt+1))

        echo "Unable to get the ingress ${ingressName}, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 5
        kubectl get ingress ${ingressName} -n ${namespaceName}
    done

    cnt=0
    ip=$(kubectl get ingress ${ingressName} -n ${namespaceName} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "Ingress ${ingressName} ip is ${ip}"
    while [ -z $ip ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            return 1
        fi
        cnt=$((cnt+1))

        sleep 30
        echo "Wait until the IP address of the ingress ${ingressName} is available, retry ${cnt} of ${MAX_RETRIES}..."
        ip=$(kubectl get ingress ${ingressName} -n ${namespaceName} -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
        echo "Ingress ${ingressName} ip is ${ip}"
    done
}

Green='\033[0;32m'
Red='\033[0;31m'
Color_Off='\033[0m'
Check_Mark='\xE2\x9C\x94'

assert_equals () {
  if [ "$1" = "$2" ]; then
    echo -e "$Green $Check_Mark Success $Color_Off"
  else
    echo -e "$Red Failed $Color_Off"
    echo -e "$Red Expected $1 to equal $2 $Color_Off"
    exit 1
  fi
}

get_json_value () {
  echo $1 | jq -r $2
}

wait_app_ready() {
    readinessCheckEndpoint=$1
    accountsEndpoint=$2
    username=$3
    password=$4

    cnt=0
    statusCode=$(curl $readinessCheckEndpoint --insecure --silent --output /dev/null --write-out '%{http_code}')
    while [ $statusCode -ne 200 ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            exit 1
        fi
        cnt=$((cnt+1))

        echo "Readiness check endpoint is not available, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 20
        statusCode=$(curl $readinessCheckEndpoint --insecure --silent --output /dev/null --write-out '%{http_code}')
    done

    cnt=0
    status=$(curl $readinessCheckEndpoint --insecure --silent | jq -r 'select(.status != null) | .status')
    while [[ UP != $status ]]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            exit 1
        fi
        cnt=$((cnt+1))

        echo "Readiness status is ${status}, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 20
        status=$(curl $readinessCheckEndpoint --insecure --silent | jq -r 'select(.status != null) | .status')
    done
    echo "Readiness status is ${status}, wait 60s before creating testing account..."
    sleep 60

    cnt=0
    statusCode=$(curl -X 'POST' \
        "$accountsEndpoint" \
        -H 'Content-Type: application/json' \
        -d '{
            "username": "'$username'",
            "password": "'$password'"
        }' \
        --insecure \
        --write-out '%{http_code}' --silent --output /dev/null)
    while [ $statusCode -ne 201 ]
    do
        if [ $cnt -eq $MAX_RETRIES ]; then
            echo "Timeout and exit due to the maximum retries reached." 
            exit 1
        fi
        cnt=$((cnt+1))

        echo "Failed to create testing account ${username}, retry ${cnt} of ${MAX_RETRIES}..."
        sleep 30
        statusCode=$(curl -X 'POST' \
            "$accountsEndpoint" \
            -H 'Content-Type: application/json' \
            -d '{
                "username": "'$username'",
                "password": "'$password'"
            }' \
            --insecure \
            --write-out '%{http_code}' --silent --output /dev/null)
    done
    echo "Successfully created testing account ${username}."
}
