ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG NGINX_IMG_TAG
FROM ${INTERNAL_REG}/debian:bullseye as certs



FROM ${EXTERNAL_REG}/nginx:${NGINX_IMG_TAG}-alpine as run
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ARG NGINX_IMG_TAG
ARG MAINTAINER
LABEL envidat.ch.nginx-img-tag="${NGINX_IMG_TAG}" \
      envidat.ch.maintainer="${MAINTAINER}"
WORKDIR /etc/nginx
# Remove default Nginx static assets
RUN rm -rf ./conf.d/default.conf ./nginx.conf
COPY . .
EXPOSE 80
