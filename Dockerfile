ARG SPARK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION

FROM maven:3-jdk-8-slim as builder
SHELL ["/bin/bash", "-c"]

ARG ZEPPELIN_REV
ARG SPARK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION

ARG ZEPPELIN_GIT_URL="https://github.com/apache/zeppelin.git"

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
    SPARK_XY_VERSION="$(echo "${SPARK_VERSION}" | cut -d '.' -f1,2 | tr -d '\n')"; \
    # The name of zeppelin directory might not be the same as the ZEPPELIN_REV, especially when building "master" where the directory might be "zeppelin-0.9.0-SNAPSHOT"
    # Below can get the actual Zeppelin version, but can only be done within Docker RUN commands
    ZEPPELIN_VERSION="$(cat pom.xml | grep "<name>Zeppelin</name>" -B1 | grep "<version>" | grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+(-SNAPSHOT)?")"; \
    ZEPPELIN_X_VERSION="$(echo "${ZEPPELIN_VERSION}" | cut -d '.' -f1)"; \
    ZEPPELIN_Y_VERSION="$(echo "${ZEPPELIN_VERSION}"  | cut -d '.' -f2)"; \
    # Cannot use Hadoop 3 due to some nested dependency version mismatch issue
    # HADOOP_X_VERSION="$(echo "${HADOOP_VERSION}" | cut -d '.' -f1 | tr -d '\n')"; \
    # change_scala_version.sh seems deprecated, doesn't even support 2.12 as a param
    # ./dev/change_scala_version.sh "${SCALA_VERSION}"; \
    # See: https://issues.apache.org/jira/browse/ZEPPELIN-3552 and https://issues.apache.org/jira/browse/ZEPPELIN-3552
    # Ignore interpreters based on the official Travis configuration
    INTERPRETERS="$(cat .travis.yml | grep INTERPRETERS= | sed -E "s/- INTERPRETERS='(.+)'/\1/" | tr -d " ")"; \
    FLAGS="-DskipTests -Pbuild-distr"; \
    MODULES="-pl ${INTERPRETERS}"; \
    # -Pscala-x.y is only used for v0.8.z, while -Pspark-scala-x.y is used for v0.9.z and onwards
    if [ "${ZEPPELIN_X_VERSION}" -eq 0 ] && [ "${ZEPPELIN_Y_VERSION}" -le 8 ]; then \
        SCALA_PROFILE_PREFIX="scala"; \
    else \
        SCALA_PROFILE_PREFIX="spark-scala"; \
    fi; \
    PROFILES="-Pspark-${SPARK_XY_VERSION} -P${SCALA_PROFILE_PREFIX}-${SCALA_VERSION} -Phadoop2"; \
    mvn clean package ${FLAGS} ${MODULES} ${PROFILES}; \
    cd -; \
    :

# Python version doesn't matter much for Zeppelin, so we just default to the latest 3.7
FROM guangie88/spark-custom-addons:${SPARK_VERSION}_scala-${SCALA_VERSION}_hadoop-${HADOOP_VERSION}_python-3.7_hive_pyspark_alpine

ENV ZEPPELIN_HOME "/zeppelin"

# Usage of wildcard works, but be aware that only the files within zeppelin-**/zeppelin-**/ will be copied over
COPY --from=builder "/tmp/zeppelin/zeppelin-distribution/target/zeppelin-**/zeppelin-**" "${ZEPPELIN_HOME}"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

# Install JAR loader
ARG ZEPPELIN_REV
ARG SCALA_VERSION

ARG ZEPPELIN_JAR_LOADER_VERSION="v0.2.1"
ENV ZEPPELIN_JAR_LOADER_VERSION "${ZEPPELIN_JAR_LOADER_VERSION}"

# Install custom OAuth authorizer with env domain checker
# This is required even for general pac4j.oauth
ARG PAC4J_AUTHORIZER_VERSION="v0.1.1"
ENV PAC4J_AUTHORIZER_VERSION "${PAC4J_AUTHORIZER_VERSION}"

RUN set -euo pipefail && \
    ZEPPELIN_X_VERSION="$(echo "${ZEPPELIN_REV}" | cut -d '.' -f1)"; \
    ZEPPELIN_Y_VERSION="$(echo "${ZEPPELIN_REV}" | cut -d '.' -f2)"; \
    # Only use the JAR loader for <= 0.8.z, since 0.9.z onwards already dropped support for it
    if [ "${ZEPPELIN_X_VERSION}" -eq 0 ] && [ "${ZEPPELIN_Y_VERSION}" -le 8 ]; then \
        wget -P ${ZEPPELIN_HOME}/lib/ https://github.com/dsaidgovsg/pac4j-authorizer/releases/download/${PAC4J_AUTHORIZER_VERSION}/pac4j-authorizer_${SCALA_VERSION}-${PAC4J_AUTHORIZER_VERSION}.jar; \
    fi; \
    :

RUN set -euo pipefail && \
    # Install gosu for non-root execution
    apk add --no-cache su-exec; \
    ln -s /sbin/su-exec /usr/local/bin/gosu; \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.4.0/tera_linux_amd64; \
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
