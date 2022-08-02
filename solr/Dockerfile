ARG EXTERNAL_REG
ARG SOLR_IMG_TAG



FROM debian:bullseye as core-builder
# Stage required due to /var/solr VOLUME directive in Solr img

ENV SOLR_CORE ckan

# Create core directories
RUN mkdir -p "/var/solr/data/$SOLR_CORE/conf" \
    "/var/solr/data/$SOLR_CORE/data"

# Add config files
COPY *.txt *.xml /var/solr/data/$SOLR_CORE/conf/

# Create core.properties
RUN echo "name=$SOLR_CORE" > "/var/solr/data/$SOLR_CORE/core.properties"



FROM ${EXTERNAL_REG}/solr:${SOLR_IMG_TAG}-slim

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}"

USER root

ENV SOLR_CORE ckan

# Add Java Topology Suite (geometry handling)
COPY --chown=solr:solr jts-core-1.18.2.jar /opt/solr/server/solr-webapp/webapp/WEB-INF/lib/

# Add security.json for BasicAuth
COPY --chown=solr:solr security.json /var/solr/data/security.json

# Copy core from multistage
COPY --chown=solr:solr --from=core-builder \
    "/var/solr/data/$SOLR_CORE" "/var/solr/data/$SOLR_CORE"

# Giving ownership to user Solr
# RUN chown -R "$SOLR_USER:$SOLR_USER" "/var/solr/data/$SOLR_CORE"

USER $SOLR_USER:$SOLR_USER
