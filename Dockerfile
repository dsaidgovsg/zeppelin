ARG SPARK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION
# Python version doesn't matter much for Zeppelin, so we just default to latest
ARG PYTHON_VERSION="3.7"

FROM maven:3-jdk-8-slim as builder
SHELL ["/bin/bash", "-c"]

ARG ZEPPELIN_REV="v0.8.1"
ARG ZEPPELIN_VERSION="0.8.1"
ARG ZEPPELIN_GIT_URL=https://github.com/apache/zeppelin.git

RUN set -euo pipefail && \
    apt-get update && apt-get install -y --no-install-recommends \
        bzip2 \
        curl \
        git \
        ; \
    # Force Node 8.x because Node 10.x doesn't work
    curl -sL https://deb.nodesource.com/setup_8.x | bash -; \
    apt-get install -y --no-install-recommends nodejs=8*; \
    rm -rf /var/lib/apt/lists/*; \
    :

# bower install step in zeppelin-web cannot be easily done as root user
RUN adduser --disabled-password --gecos "" installer
USER installer

ARG SCALA_VERSION

# Build from source and install from tar package
RUN set -euo pipefail && \
    cd /tmp; \
    git clone ${ZEPPELIN_GIT_URL} -b ${ZEPPELIN_REV}; \
    cd -; \
    cd /tmp/zeppelin; \
    mvn clean package -DskipTests -Pbuild-distr "-Pscala-${SCALA_VERSION}"; \
    cd -; \
    :

FROM guangie88/spark-custom-addons:${SPARK_VERSION}_scala-${SCALA_VERSION}_hadoop-${HADOOP_VERSION}_python-${PYTHON_VERSION}_hive_pyspark_alpine

ENV ZEPPELIN_HOME "/zeppelin"
COPY --from=builder "/tmp/zeppelin/zeppelin-distribution/target/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}" "${ZEPPELIN_HOME}"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

ARG ZEPPELIN_VERSION
ENV ZEPPELIN_VERSION "${ZEPPELIN_VERSION}"

# Install JAR loader
ARG SCALA_VERSION

ARG ZEPPELIN_JAR_LOADER_VERSION="v0.2.1"
ENV ZEPPELIN_JAR_LOADER_VERSION "${ZEPPELIN_JAR_LOADER_VERSION}"

RUN set -euo pipefail && \
    wget -P ${SPARK_HOME}/jars/ https://github.com/dsaidgovsg/zeppelin-jar-loader/releases/download/${ZEPPELIN_JAR_LOADER_VERSION}/zeppelin-jar-loader_${SCALA_VERSION}-${ZEPPELIN_JAR_LOADER_VERSION}.jar; \
    :

# Install custom OAuth authorizer with env domain checker
# This is required even for general pac4j.oauth
ARG PAC4J_AUTHORIZER_VERSION="v0.1.1"
ENV PAC4J_AUTHORIZER_VERSION "${PAC4J_AUTHORIZER_VERSION}"

RUN set -euo pipefail && \
    wget -P ${ZEPPELIN_HOME}/lib/ https://github.com/dsaidgovsg/pac4j-authorizer/releases/download/${PAC4J_AUTHORIZER_VERSION}/pac4j-authorizer_${SCALA_VERSION}-${PAC4J_AUTHORIZER_VERSION}.jar; \
    :

RUN set -euo pipefail && \
    # Install gosu for non-root execution
    apk add --no-cache su-exec; \
    ln -s /sbin/su-exec /usr/bin/gosu; \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.2.1/tera_linux_amd64; \
    chmod +x tera_linux_amd64; \
    mv tera_linux_amd64 /usr/local/bin/tera; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN adduser -D zeppelin

ENV ZEPPELIN_IMPERSONATE_USER zeppelin
ENV ZEPPELIN_IMPERSONATE_CMD "gosu zeppelin bash -c "
ENV ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER false

# Env var not expanded without Dockerfile, so need to go through sh
CMD ["sh", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
