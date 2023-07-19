ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG PYTHON_IMG_TAG



FROM ${EXTERNAL_REG}/debian:bullseye AS certs
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates



FROM ${EXTERNAL_REG}/python:${PYTHON_IMG_TAG}-slim-bullseye as base
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



FROM base as extract-deps
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        git \
    && rm -rf /var/lib/apt/lists/*
# Clone repos
WORKDIR /opt/repos
ARG CKAN_VERSION
RUN git clone -b "$CKAN_VERSION" --depth 1 \
    https://github.com/ckan/ckan.git
# Merge requirements to single file &
# add flask-debugtoolbar to enable debug mode
WORKDIR /opt/requirements
RUN cp /opt/repos/ckan/requirements.txt \
      ./requirements-ckan.txt
RUN grep Flask-DebugToolbar \
      < /opt/repos/ckan/dev-requirements.txt \
      >> ./requirements-ckan.txt
# Add extra deps
COPY requirements-extra.txt .
RUN cat ./requirements-extra.txt \
      >> ./requirements-ckan.txt
# Import deps to PDM
RUN pip install --no-cache-dir pdm==2.6.0 \
    && pdm config python.use_venv false
RUN pdm init --non-interactive \
    && pdm import -f requirements \
       ./requirements-ckan.txt
# Add ckan to requirements & lock / check conflicts
RUN pdm add --no-sync \
    "git+https://github.com/ckan/ckan.git@$CKAN_VERSION"
# Export to single requirements file
RUN pdm export --without-hashes --prod > requirements.txt



FROM base as build
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        git \
        build-essential \
        gcc \
        python3-dev \
        libpq-dev \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt/python
COPY --from=extract-deps \
    /opt/requirements/requirements.txt .
# Fix for CKAN 2.9
RUN pip install --no-cache-dir --upgrade setuptools==45
# Install deps, including CKAN
RUN pip install --user --no-warn-script-location \
    --no-cache-dir -r ./requirements.txt
COPY envidat_extensions.* ./
# Plugin sub-dependencies
RUN chmod +x /opt/python/envidat_extensions.sh \
    && /opt/python/envidat_extensions.sh
# Install plugins
RUN pip install --user --no-warn-script-location \
    --no-cache-dir -r ./envidat_extensions.txt



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
        libgeos-c1v5 \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build \
    /root/.local \
    $CKAN_HOME/.local
COPY ckan-entrypoint.sh /ckan-entrypoint.sh
COPY wsgi.py who.ini envidat_licenses.json $CKAN_CONFIG_DIR/
# Upgrade pip & pre-compile deps to .pyc, add ckan user, permissions
RUN python -c "import compileall; compileall.compile_path(maxlevels=10, quiet=1)" \
    && useradd -r -u 900 -m -c "non-priv user" -d $CKAN_HOME -s /bin/false ckanuser \
    && chmod +x /ckan-entrypoint.sh \
    && mkdir -p $CKAN_HOME $CKAN_STORAGE_PATH/storage/uploads/group \
    && chown -R ckanuser:ckanuser $CKAN_HOME $CKAN_CONFIG_DIR
USER ckanuser
ENTRYPOINT ["/ckan-entrypoint.sh"]



FROM runtime as debug
RUN pip install --no-cache-dir debugpy==1.6.4 --no-cache
COPY debug_run.py .
CMD ["python", "-m", "debugpy", \
    "--listen", "0.0.0.0:5678", \
    "debug_run.py", "--", "run", "--host", "0.0.0.0", "--passthrough-errors"]
    # "--disable-debugger"]



FROM runtime as prod
# CMD ["opentelemetry-instrument", "gunicorn", "wsgi:application", \
#         "--bind", "0.0.0.0:5000", \
#         "--workers=2", "--threads=4", "--worker-class=gthread", \
#         "--worker-tmp-dir=/dev/shm", \
#         "--log-file=-", "--log-level=debug"]
CMD ["gunicorn", "wsgi:application", \
        "--bind", "0.0.0.0:5000", \
        "--workers=2", "--threads=4", "--worker-class=gthread", \
        "--worker-tmp-dir=/dev/shm", \
        "--log-file=-", "--log-level=debug"]
