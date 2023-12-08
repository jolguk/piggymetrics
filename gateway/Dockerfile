ARG NGINX_VERSION=1.25.2
ARG OTEL_MODULE_VERSION=0.1.0
FROM nginx-otel:${NGINX_VERSION}-${OTEL_MODULE_VERSION}

COPY webapp /usr/share/nginx/webapp
COPY nginx/certfile.pem /etc/ssl/certfile.pem
COPY nginx/keyfile.key /etc/ssl/keyfile.key
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY nginx/entrypoint.sh /

ENV LOG_DIRECTORY=/var/log/nginx
ENV JAEGER_URL=localhost:4317
ENV AUTH_SERVICE_URL=http://localhost:9180
ENV ACCOUNT_SERVICE_URL=http://localhost:9280
ENV STATISTICS_SERVICE_URL=http://localhost:9380
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
