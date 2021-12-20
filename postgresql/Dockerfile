FROM postgis/postgis:12-3.2

ARG MAINTAINER
LABEL MAINTAINER ${MAINTAINER}

# Allow connections; we don't map out any ports so only linked docker containers can connect
RUN echo "host all  all    0.0.0.0/0  md5" >> /var/lib/postgresql/data/pg_hba.conf

# Include setup scripts
COPY ./docker-entrypoint-initdb.d /docker-entrypoint-initdb.d
