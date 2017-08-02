# VERSION 1.8.1
# AUTHOR: Naveen "nave91"
# DESCRIPTION: Basic Airflow container with priest
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/bellhops/docker-airflow

FROM python:3.6
MAINTAINER Naveen

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Airflow
ARG AIRFLOW_VERSION=1.8.1
ARG AIRFLOW_HOME=/usr/local/airflow
ARG GIT_KEY=testkey
ARG PRIEST_GIT_URL=github.com/bellhops/priest
ARG PRIEST_GIT_BRANCH=master

# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# DOcker inside docker
RUN set -ex \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg2 \
        software-properties-common
RUN set -ex \
    && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    && apt-get update -yqq \
    && apt-get install -yqq docker-ce

# Airflow installs
RUN set -ex \
    && apt-get install -yqq --no-install-recommends \
        python3-dev \
        libkrb5-dev \
        libsasl2-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
        libpq-dev \
	    libssl-dev \
        python3-pip \
        python3-requests \
        apt-utils \
        curl \
	    git \
        netcat \
        locales \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
RUN set -ex \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && python3 -m pip install -U pip \
    && pip -V

CMD echo "git clone -b ${PRIEST_GIT_BRANCH} https://${GIT_KEY}@${PRIEST_GIT_URL} ${AIRFLOW_HOME}/shared/priest"
RUN git clone -b ${PRIEST_GIT_BRANCH} https://${GIT_KEY}@${PRIEST_GIT_URL} ${AIRFLOW_HOME}/shared/priest
RUN cp -R ${AIRFLOW_HOME}/shared/priest/dags ${AIRFLOW_HOME}/dags

RUN set -ex \
    && pip install Cython \
    && pip install pytz \
    && pip install apache-airflow[s3,celery,postgres,hive,hdfs,jdbc]==$AIRFLOW_VERSION \
    && pip install celery[redis]==3.1.17 \
    && pip install flask-bcrypt==0.7.1

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN set -ex \
    && pip install -r ${AIRFLOW_HOME}/shared/priest/requirements.txt

RUN chown -R airflow: ${AIRFLOW_HOME}

# Add sudo permissions for debugging
RUN set -ex \
    && apt-get install sudo \
    && echo "airflow:airflow" | chpasswd \
    && usermod -aG sudo airflow

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
