ARG EXTERNAL_REG
FROM ${EXTERNAL_REG}/solr:6.6.5

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}" 

# Enviroment
ENV SOLR_CORE ckan

# Create Directories
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/conf \
    && mkdir -p /opt/solr/server/solr/$SOLR_CORE/data

# Add Config Files
COPY . /opt/solr/server/solr/$SOLR_CORE/conf/

# Create Core.properties
RUN echo name=$SOLR_CORE > /opt/solr/server/solr/$SOLR_CORE/core.properties

# Giving ownership to Solr
USER root
RUN chown -R "$SOLR_USER:$SOLR_USER" "/opt/solr/server/solr/$SOLR_CORE"

# User
USER $SOLR_USER:$SOLR_USER
