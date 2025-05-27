
ARG EXTERNAL_REG
ARG INTERNAL_REG
ARG PYTHON_IMG_TAG
FROM ${EXTERNAL_REG}/debian:bullseye AS certs
RUN echo "**** Step 1: updating debian:bullseye certs"
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates
RUN echo "**** Step 2: Base image definition"
FROM ${EXTERNAL_REG}/python:${PYTHON_IMG_TAG}-slim-bullseye as base
ARG PYTHON_IMG_TAG
ARG CKAN_VERSION
ARG MAINTAINER
LABEL envidat.ch.python-img-tag="${PYTHON_IMG_TAG}" \
      envidat.ch.ckan-version="${CKAN_VERSION}" \
      envidat.ch.maintainer="${MAINTAINER}" \
      envidat.ch.api-port="5000"
RUN echo "**** Step 3: Copy certs"
# CA-Certs
COPY --from=certs \
    /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
RUN echo "**** Step 4: install locals"
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
       -y --no-install-recommends locales \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*
 \
    # Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN echo "**** Step 5: Install git"
FROM base as extract-deps
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        git \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*
RUN echo "**** Step 6: git clone ckan-forked sources"
# Clone repos
WORKDIR /opt/repos
ARG CKAN_VERSION
RUN git clone -b "$CKAN_VERSION" --depth 1 \
    https://github.com/EnviDat/ckan-forked.git
#RUN echo "**** Step 10: Install PDM and set up environment"
#WORKDIR /opt/requirements
# Install PDM
#RUN pip install --no-cache-dir --upgrade pip \
#    && pip install pdm==2.24.1 \
#    && pdm config python.use_venv false
#RUN echo "**** Step 12: Initialize PDM project and import dependencies"
# Initialize PDM and import dependencies from the modified requirements file
#RUN pdm init --python 3.9
# Install the dependencies as defined in the lock file
#RUN pdm install

#RUN echo "**** Step 7: merge requirements.txt into requirements-ckan.txt"
#RUN cp /opt/repos/ckan-forked/requirements.txt ./requirements-ckan.txt
#RUN echo "**** Step 8: Add flask-debugtoolbar to enable debug mode"
# Add flask-debugtoolbar to enable debug mode
#RUN grep flask-debugtoolbar \
#      < /opt/repos/ckan-forked/dev-requirements.txt \
#      >> ./requirements-ckan.txt
#RUN echo "**** Step 9: merge extras, requirements-extra.txt into requirements-ckan.txt"
# Add extra deps
#COPY requirements-extra.txt /opt/repos/
#RUN cat /opt/repos/requirements-extra.txt \
#      >> ./requirements-ckan.txt
#RUN echo "**** Step 10: Install pip and install ckan-forked.git@2.9"
#RUN pip install /opt/repos/ckan-forked

#RUN echo "**** Step 13: Add CKAN from GitHub to PDM dependencies"
# Add CKAN from GitHub 
#RUN pdm add "git+https://github.com/EnviDat/ckan-forked.git@$CKAN_VERSION"
#RUN echo "**** Step 11: Modify requirements (replace psycopg2 with psycopg2-binary)"
# Replace psycopg2 with psycopg2-binary
#RUN sed -i 's/psycopg2==2.9.3/psycopg2-binary==2.9.3/' ./requirements-ckan.txt
#RUN pdm import -f requirements ./requirements-ckan.txt
#RUN pdm install

RUN echo "**** Step 7: copy various dependencies into /opt/python and extract the requirements there?"
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
RUN echo "**** Step 8: Install PDM and set up environment"
RUN pip install --upgrade pip && pip install pdm==2.24.1
RUN pdm config python.use_venv false
COPY --from=extract-deps /opt/repos/ckan-forked ./ckan-forked
COPY envidat_extensions.* ./
RUN echo "**** Step 9: Plugin sub-dependencies /opt/python/envidat_extensions.sh"
# Copy only dependency files first for better caching
COPY pyproject.toml pdm.lock ./
# Plugin sub-dependencies
RUN chmod +x /opt/python/envidat_extensions.sh \
    && /opt/python/envidat_extensions.sh
# Copy only dependency files first for better caching
COPY pyproject.toml pdm.lock ./
# Install the dependencies as defined in the lock file
RUN pdm install
RUN pdm lock
RUN pip install --user --no-warn-script-location \
    --no-cache-dir -r ./envidat_extensions.txt
# After all PDM steps
RUN pdm export --without-hashes --prod > requirements.txt \
    && pip install  --user --no-cache-dir -r requirements.txt

RUN echo "**** Step 10: define runtime and change to /opt/ckan, copy ckan-entrypoint.sh and other files"
FROM base as runtime
ARG PYTHON_IMG_TAG
WORKDIR /opt/ckan
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONPATH="/usr/lib/ckan/.local/lib/python3.9/site-packages:$PYTHONPATH" \
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
        git \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build \
    /root/.local \
    $CKAN_HOME/.local
COPY --from=extract-deps /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=extract-deps /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /opt/python/ckanext $CKAN_LIB/ckanext
COPY ckan-entrypoint.sh /ckan-entrypoint.sh
COPY wsgi.py config/who.ini config/envidat_licenses.json $CKAN_CONFIG_DIR/
RUN echo "**** Step 11: Upgrade pip & pre-compile deps to .pyc, add ckan user, permissions. Also run ckan-entrypoint.sh"
# Upgrade pip & pre-compile deps to .pyc, add ckan user, permissions
RUN python -c "import compileall; compileall.compile_path(maxlevels=10, quiet=1)" \
    && python -c "import compileall; compileall.compile_path(maxlevels=10, quiet=1)" \
    && useradd -r -u 900 -m -c "non-priv user" -d $CKAN_HOME -s /bin/false ckanuser \
    && chmod +x /ckan-entrypoint.sh \
    && mkdir -p $CKAN_HOME $CKAN_STORAGE_PATH/storage/uploads/group \
    && chown -R ckanuser:ckanuser $CKAN_HOME $CKAN_CONFIG_DIR
USER ckanuser
ENTRYPOINT ["/ckan-entrypoint.sh"]
RUN echo "**** Step 12: Run CKAN application"

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
