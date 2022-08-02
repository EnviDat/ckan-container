ARG EXTERNAL_REG
ARG POSTGRES_IMG_VERSION
ARG POSTGIS_IMG_VERSION

FROM ${EXTERNAL_REG}/postgis/postgis:${POSTGRES_IMG_VERSION}-${POSTGIS_IMG_VERSION}

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}" 

# Allow connections; we don't map out any ports so only linked docker containers can connect
RUN echo "host all  all    0.0.0.0/0  md5" >> /var/lib/postgresql/data/pg_hba.conf

# Include setup scripts
COPY ./docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
