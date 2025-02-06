ARG EXTERNAL_REG
ARG SOLR_IMG_TAG



FROM ${EXTERNAL_REG}/solr:${SOLR_IMG_TAG}-slim

ENV SOLR_CORE ckan

ARG SOLR_IMG_TAG
ARG MAINTAINER
LABEL envidat.ch.solr-img-tag="${SOLR_IMG_TAG}" \
      envidat.ch.maintainer="${MAINTAINER}" \
      envidat.ch.api-port="8983" \
      envidat.ch.solr-core-name="${SOLR_CORE}"

ARG JTS_VERSION="1.19.0"
ARG JTS_JAR_FILE="$SOLR_INSTALL/server/solr-webapp/webapp/WEB-INF/lib/jts-core-$JTS_VERSION.jar"

USER root

# Add config files
COPY --chown=solr:solr *.txt *.xml /var/solr/data/$SOLR_CORE/conf/
# Add security.json for BasicAuth
COPY --chown=solr:solr security.json /var/solr/data/security.json
# Create core.properties & give ownership to user Solr
RUN echo "**** Check Solr user:"
RUN echo $SOLR_USER
RUN echo "name=$SOLR_CORE" > "/var/solr/data/$SOLR_CORE/core.properties" \
    && chown -R "$SOLR_USER:$SOLR_USER" "/var/solr/data/$SOLR_CORE"

# Add Java Topology Suite (geometry handling)
ADD https://repo1.maven.org/maven2/org/locationtech/jts/jts-core/$JTS_VERSION/jts-core-$JTS_VERSION.jar \
    $JTS_JAR_FILE
RUN chmod 644 $JTS_JAR_FILE

# # Add the spatial field type definitions and fields
# ## RPT
# ENV SOLR_RPT_FIELD_DEFINITION '<fieldType name="location_rpt"   class="solr.SpatialRecursivePrefixTreeFieldType" \
#     spatialContextFactory="JTS"     \
#     autoIndex="true"                \
#     validationRule="repairBuffer0"  \
#     distErrPct="0.025"              \
#     maxDistErr="0.001"              \
#     distanceUnits="kilometers" />'

# ENV SOLR_RPT_FIELD '<field name="spatial_geom" type="location_rpt" indexed="true" multiValued="true" />'

# RUN sed -i "/<types>/a $SOLR_RPT_FIELD_DEFINITION" $SOLR_SCHEMA_FILE
# RUN sed -i "/<fields>/a $SOLR_RPT_FIELD" $SOLR_SCHEMA_FILE

# ## BBox
# ENV SOLR_BBOX_FIELDS '<field name="bbox_area" type="float" indexed="true" stored="true" /> \
#     <field name="maxx" type="float" indexed="true" stored="true" /> \
#     <field name="maxy" type="float" indexed="true" stored="true" /> \
#     <field name="minx" type="float" indexed="true" stored="true" /> \
#     <field name="miny" type="float" indexed="true" stored="true" />'

# RUN sed -i "/<fields>/a $SOLR_BBOX_FIELDS" $SOLR_SCHEMA_FILE

USER $SOLR_USER:$SOLR_USER
