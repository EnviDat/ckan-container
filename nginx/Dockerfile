ARG EXTERNAL_REG
ARG NGINX_IMG_TAG



FROM ${EXTERNAL_REG}/debian:bullseye AS certs
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates



FROM ${EXTERNAL_REG}/nginx:${NGINX_IMG_TAG} as run
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ARG NGINX_IMG_TAG
ARG MAINTAINER
LABEL envidat.ch.nginx-img-tag="${NGINX_IMG_TAG}" \
      envidat.ch.maintainer="${MAINTAINER}"
RUN apt-get update && apt-get install\
    -y --no-install-recommends \
        wait-for-it \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /etc/nginx
# Remove default Nginx static assets
RUN rm -rf ./conf.d/default.conf ./nginx.conf
COPY nginx.conf nginx.conf
COPY --chmod=744 00-wait-for-start.sh /docker-entrypoint.d/
ARG NGINX_CONFIG_NAME
COPY templates/${NGINX_CONFIG_NAME}.template templates/ckan.conf.template
EXPOSE 80
