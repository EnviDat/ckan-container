ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG NGINX_IMG_VERSION
FROM ${INTERNAL_REG}/debian:bullseye as certs



FROM ${EXTERNAL_REG}/nginx:${NGINX_IMG_VERSION} as build

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update\
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        --no-install-recommends \
        openssh-client \
        wget \
        libxml2 \
        libxslt1-dev \
        libpcre3 \
        libpcre3-dev \
        zlib1g \
        zlib1g-dev \
        openssl \
        libssl-dev \
        libtool \
        automake \
        gcc \
        g++ \
        make \
    && rm -rf /var/lib/apt/lists/*

RUN wget --progress=dot:giga \
    "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" && \
    tar -C /usr/src -xzvf "nginx-${NGINX_VERSION}.tar.gz"

WORKDIR /src
ARG NGINX_REDIS_VERSION=0.3.9
RUN wget --progress=dot:giga \
    "https://people.freebsd.org/~osa/ngx_http_redis-${NGINX_REDIS_VERSION}.tar.gz" \
    && tar -C /src -xzvf "ngx_http_redis-${NGINX_REDIS_VERSION}.tar.gz"

ARG NGINX_IMG_VERSION
WORKDIR /usr/src/nginx-${NGINX_IMG_VERSION}
# hadolint ignore=SC2097,SC2098
RUN NGINX_ARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
    ./configure --with-compat --with-http_ssl_module \
    --add-dynamic-module=/src/ngx_http_redis-"${NGINX_REDIS_VERSION}" \
    "${NGINX_ARGS}" \
    && make modules



FROM ${EXTERNAL_REG}/nginx:${NGINX_IMG_VERSION}-alpine as run
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ARG NGINX_IMG_VERSION
ARG MAINTAINER
LABEL envidat.ch.nginx-img-tag="${NGINX_IMG_VERSION}" \
      envidat.ch.maintainer="${MAINTAINER}"
# Modules
COPY --from=build \
    /usr/src/nginx-${NGINX_IMG_VERSION}/objs/ngx_http_redis_module.so \
    /usr/lib/nginx/modules/
WORKDIR /etc/nginx
# Remove default Nginx static assets
RUN rm -rf ./conf.d/default.conf ./nginx.conf
COPY . .
EXPOSE 80
