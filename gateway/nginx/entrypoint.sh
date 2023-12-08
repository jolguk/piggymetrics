#!/usr/bin/env sh
set -eu

envsubst '${LOG_DIRECTORY} ${JAEGER_URL} ${AUTH_SERVICE_URL} ${ACCOUNT_SERVICE_URL} ${STATISTICS_SERVICE_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

exec "$@"
