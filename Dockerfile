ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG PYTHON_IMG_TAG



FROM ${EXTERNAL_REG}/debian:bookworm AS certs
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates



FROM ${EXTERNAL_REG}/python:${PYTHON_IMG_TAG}-slim-bookworm as base
ARG PYTHON_IMG_TAG
ARG CKAN_VERSION
ARG MAINTAINER
LABEL envidat.ch.python-img-tag="${PYTHON_IMG_TAG}" \
      envidat.ch.ckan-version="${CKAN_VERSION}" \
      envidat.ch.maintainer="${MAINTAINER}" \
      envidat.ch.api-port="5000"
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
       -y --no-install-recommends locales \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*
# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8



FROM base as build
ARG CKAN_VERSION
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        git \
        build-essential \
        gcc \
        python3-dev \
        libpq-dev \
        libssl-dev \
        libffi-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/python
COPY requirements-extra.txt .
# Install CKAN, plus extra deps
RUN pip install --user --no-warn-script-location \
    --no-cache-dir "ckan[requirements]==$CKAN_VERSION" \
    && pip install --user --no-warn-script-location \
    --no-cache-dir -r ./requirements-extra.txt \
    && rm requirements-extra.txt
# Install ckanext-scheming (not updated on PyPi)
RUN pip install --user --no-warn-script-location \
    --no-cache-dir git+https://github.com/ckan/ckanext-scheming.git
# Install ckanext-blind_review (not on PyPi)
RUN pip install --user --no-warn-script-location \
    --no-cache-dir git+https://gitlabext.wsl.ch/EnviDat/ckanext-blind_review.git#egg=ckanext-blind_review




FROM base as runtime
ARG PYTHON_IMG_TAG
WORKDIR /opt/ckan
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PATH="/usr/lib/ckan/.local/bin:$PATH" \
    CKAN_HOME="/usr/lib/ckan" \
    CKAN_CONFIG_DIR="/opt/ckan" \
    CKAN_STORAGE_PATH="/opt/ckan/data" \
    CKAN_LIB="/usr/lib/ckan/.local/lib/python$PYTHON_IMG_TAG/site-packages"
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        curl \
        postgresql-client \
        libpq-dev \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build \
    /root/.local \
    $CKAN_HOME/.local
COPY ckan-entrypoint.sh /ckan-entrypoint.sh
COPY wsgi.py config/*.yaml config/*.json $CKAN_CONFIG_DIR/
# Upgrade pip & add ckan user, permissions
RUN useradd -r -u 900 -m -c "non-priv user" -d $CKAN_HOME -s /bin/false ckanuser \
    && chmod +x /ckan-entrypoint.sh \
    && mkdir -p $CKAN_HOME $CKAN_STORAGE_PATH/storage/uploads/group \
    && chown -R ckanuser:ckanuser $CKAN_HOME $CKAN_CONFIG_DIR
ENTRYPOINT ["/ckan-entrypoint.sh"]



FROM runtime as debug
ARG CKAN_VERSION
USER ckanuser
RUN pip install --user --no-cache-dir --no-cache \
    debugpy==1.6.4  \
    "ckan[dev]==$CKAN_VERSION"
CMD ["python", "-m", "debugpy", "--listen", "0.0.0.0:5678", \
    "/usr/lib/ckan/.local/bin/ckan", "run", "--host", "0.0.0.0", \
    "--passthrough-errors"]
    # "--disable-debugger"]



FROM runtime as prod
# CMD ["opentelemetry-instrument", "gunicorn", "wsgi:application", \
#         "--bind", "0.0.0.0:5000", \
#         "--workers=2", "--threads=4", "--worker-class=gthread", \
#         "--worker-tmp-dir=/dev/shm", \
#         "--log-file=-", "--log-level=debug"]
# Pre-compile packages to .pyc (init speed gains)
RUN python -c "import compileall; compileall.compile_path(maxlevels=10, quiet=1)"
USER ckanuser
CMD ["gunicorn", "wsgi:application", \
        "--bind", "0.0.0.0:5000", \
        "--workers=2", "--threads=4", "--worker-class=gthread", \
        "--worker-tmp-dir=/dev/shm", \
        "--log-file=-", "--log-level=debug"]
