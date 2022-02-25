ARG EXTERNAL_REG
ARG SOLR_VERSION

FROM ${EXTERNAL_REG}/solr:${SOLR_VERSION}

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}" 

# Enviroment
ENV SOLR_CORE ckan

# Create Directories
RUN mkdir -p /opt/solr/server/solr/$SOLR_CORE/conf \
    && mkdir -p /opt/solr/server/solr/$SOLR_CORE/data

# Add Config Files
COPY --chown=solr:solr *.txt *.xml /opt/solr/server/solr/$SOLR_CORE/conf/
# Check location of security.json
COPY --chown=solr:solr security.json /opt/solr/server/solr/security.json
COPY --chown=solr:solr jts-core-1.14.0.jar /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/

# Create Core.properties
RUN echo name=$SOLR_CORE > /opt/solr/server/solr/$SOLR_CORE/core.properties

# Giving ownership to Solr
USER root
RUN chown -R "$SOLR_USER:$SOLR_USER" "/opt/solr/server/solr/$SOLR_CORE"

# User
USER $SOLR_USER:$SOLR_USER
