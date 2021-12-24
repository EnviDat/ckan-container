ARG EXTERNAL_REG
ARG PYTHON_VERSION

FROM ${EXTERNAL_REG}/python:${PYTHON_VERSION}-slim-bullseye as base

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
       -y --no-install-recommends locales \
    && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8



FROM base as build

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        build-essential \
        gcc \
        libpq-dev \
        git \
        libxml2-dev \
        libxslt-dev \
        libgeos-dev \
        libssl-dev \
        libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/repos
ARG CKAN_VERSION
RUN git clone -b "$CKAN_VERSION" --depth 1 \
    https://github.com/EnviDat/ckan-forked.git

WORKDIR /opt/python
# Requirements
RUN pip install --no-cache-dir pipenv==11.9.0 \
    # workarounds for python 3.9 + require setuptools <44
    && sed -i -E "/zope\.interface/s/==.*/==5.2.0/" \
       /opt/repos/ckan-forked/requirements.txt \
    && sed -i -E "/markdown/s/==.*/==3.3.3/" \
       /opt/repos/ckan-forked/requirements.txt \
    && PIPENV_VENV_IN_PROJECT=1 pipenv install \
       -r /opt/repos/ckan-forked/requirements.txt
# CKAN
RUN PIPENV_VENV_IN_PROJECT=1 pipenv run \
        python -m pip install "/opt/repos/ckan-forked"
# Additional plugins
COPY envidat_extensions.* /opt/repos/
RUN chmod +x /opt/repos/envidat_extensions.sh \
    && /opt/repos/envidat_extensions.sh
RUN PIPENV_VENV_IN_PROJECT=1 pipenv run \
        python -m pip install -r "/opt/repos/envidat_extensions.txt" \
    && rm /opt/python/Pipfile /opt/python/Pipfile.lock



FROM base as runtime

ARG PYTHON_VERSION
ARG CKAN_VERSION
ARG MAINTAINER
LABEL envidat.com.python-img-tag="${PYTHON_VERSION}" \
      envidat.com.ckan-version="${CKAN_VERSION}" \
      envidat.com.maintainer="${MAINTAINER}"
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONFAULTHANDLER=1

RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y --no-install-recommends \
        libpcre3 \
        postgresql-client \
        libgeos-c1v5 \
        libmagic1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/python

COPY --from=build \
    /opt/python/ \
    /opt/python/

ENV PATH="/opt/python/.venv/bin:$PATH"
ENV CKAN_HOME /usr/lib/ckan
ENV CKAN_CONFIG /etc/ckan

COPY config/who.ini $CKAN_CONFIG/
COPY ckan-entrypoint.sh /ckan-entrypoint.sh

# Upgrade pip & pre-compile deps to .pyc, add ckan user, permissions
RUN /opt/python/.venv/bin/python -m pip install --no-cache --upgrade pip \
    && python -c "import compileall; compileall.compile_path(maxlevels=10, quiet=1)" \
    && useradd -r -u 900 -m -c "ckan account" -d $CKAN_HOME -s /bin/false ckan \
    && chmod +x /ckan-entrypoint.sh \
    && chown -R ckan:ckan $CKAN_HOME $CKAN_CONFIG

ENTRYPOINT ["/ckan-entrypoint.sh"]
USER ckan
EXPOSE 5000
CMD ["ckan", "-c", "/etc/ckan/production.ini", "run", "--host", "0.0.0.0"]
