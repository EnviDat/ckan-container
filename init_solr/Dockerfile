ARG EXTERNAL_REG
FROM ${EXTERNAL_REG}/bash:5

ARG MAINTAINER
LABEL maintainer="${MAINTAINER}" 

RUN apk add --no-cache curl
COPY init.sh /
RUN chmod +x /init.sh
ENTRYPOINT ["/init.sh"]
