ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG NGINX_VERSION
FROM ${INTERNAL_REG}/debian:bullseye as certs



FROM ${EXTERNAL_REG}/nginx:${NGINX_VERSION}-alpine
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ARG NGINX_VERSION
ARG MAINTAINER
LABEL envidat.ch.nginx-img-tag="${NGINX_VERSION}" \
      envidat.ch.maintainer="${MAINTAINER}"
WORKDIR /etc/nginx
# Remove default Nginx static assets
RUN rm -rf ./conf.d/default.conf ./nginx.conf
COPY . .
EXPOSE 80
