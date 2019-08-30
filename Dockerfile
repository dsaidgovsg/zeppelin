ARG FROM_DOCKER_IMAGE=

FROM maven:3-jdk-8-slim as builder
SHELL ["/bin/bash", "-c"]

ARG ZEPPELIN_REV="master"
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

# Build from source and install from tar package
RUN set -euo pipefail && \
    cd /tmp; \
    git clone ${ZEPPELIN_GIT_URL} -b ${ZEPPELIN_REV}; \
    cd -; \
    cd /tmp/zeppelin; \
    mvn clean package -DskipTests -Pbuild-distr; \
    cd -; \
    :

FROM ${FROM_DOCKER_IMAGE}

ENV ZEPPELIN_HOME "/zeppelin"
COPY --from=builder /tmp/zeppelin/zeppelin-distribution/target/zeppelin-0.9.0-SNAPSHOT/zeppelin-0.9.0-SNAPSHOT "${ZEPPELIN_HOME}"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

# Need to use back root to perform these actions
# In any case the image is meant for Zeppelin with Spark-k8s extension, so it's okay to go with root
USER root

# # Install Zeppelin from pre-built package
# RUN wget -O - https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz | \
#         tar xz --strip-components=1 -C ${ZEPPELIN_HOME} zeppelin-${ZEPPELIN_VERSION}-bin-netinst

# ARG ZEPPELIN_OTHER_INTERPRETERS=
# RUN if [ ! -z "${ZEPPELIN_OTHER_INTERPRETERS}" ]; then \
#         ./bin/install-interpreter.sh --name "${ZEPPELIN_OTHER_INTERPRETERS}"; \
#     fi

# Install JAR loader
ARG ZEPPELIN_JAR_LOADER_VERSION=v0.2.0
ENV ZEPPELIN_JAR_LOADER_VERSION "${ZEPPELIN_JAR_LOADER_VERSION}"
RUN wget -P ${SPARK_HOME}/jars/ https://github.com/dsaidgovsg/zeppelin-jar-loader/releases/download/${ZEPPELIN_JAR_LOADER_VERSION}/zeppelin-jar-loader-${ZEPPELIN_JAR_LOADER_VERSION}.jar

# Install env domain authorizer
ARG PAC4J_AUTHORIZER_VERSION=v0.1.0
ENV PAC4J_AUTHORIZER_VERSION "${PAC4J_AUTHORIZER_VERSION}"
RUN wget -P ${ZEPPELIN_HOME}/lib/ https://github.com/dsaidgovsg/pac4j-authorizer/releases/download/${PAC4J_AUTHORIZER_VERSION}/pac4j-authorizer-${PAC4J_AUTHORIZER_VERSION}.jar

RUN set -euo pipefail && \
    # Install gosu for non-root execution
    apk add --no-cache su-exec; \
    ln -s /sbin/su-exec /usr/bin/gosu; \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.2.0/tera_linux_amd64; \
    chmod +x tera_linux_amd64; \
    mv tera_linux_amd64 /usr/local/bin/tera; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN adduser -D zeppelin

ENV ZEPPELIN_IMPERSONATE_USER zeppelin
ENV ZEPPELIN_IMPERSONATE_CMD "gosu zeppelin bash -c "
ENV ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER false

ENTRYPOINT []
CMD ["sh", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
