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

# bower install step in zeppelin-web cannot be easily done as root userc
RUN adduser --disabled-password --gecos "" installer
USER installer

# Build from source and install from tar package
RUN set -euo pipefail && \
    cd /tmp; \
    git clone ${ZEPPELIN_GIT_URL}; \
    cd -; \
    cd /tmp/zeppelin; \
    git checkout ${ZEPPELIN_REV}; \
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
FROM dsaidgovsg/spark-k8s-addons:v4_${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_python-3.7
USER root

ENV ZEPPELIN_HOME "/zeppelin"

# Usage of wildcard works, but be aware that only the files within zeppelin-**/zeppelin-**/ will be copied over
COPY --from=builder "/tmp/zeppelin/zeppelin-distribution/target/zeppelin-**/zeppelin-**" "${ZEPPELIN_HOME}"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

# Install JAR loader
ARG ZEPPELIN_REV
ARG SCALA_VERSION

# Install required apt packages
RUN set -euo pipefail && \
    apt-get update && apt-get install -y --no-install-recommends \
        fuse \
        gosu \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*; \
    :

# Install GitHub Release Assets FUSE mount CLI (requires fuse install)
ARG GHAFS_VERSION="v0.1.3"
RUN set -euo pipefail && \
    wget https://github.com/guangie88/ghafs/releases/download/${GHAFS_VERSION}/ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    tar xvf ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    rm ghafs-${GHAFS_VERSION}-linux-amd64.tar.gz; \
    mv ./ghafs /usr/local/bin/; \
    ghafs --version; \
    :

# Install custom OAuth authorizer with env domain checker
# This is required even for general pac4j.oauth
ARG PAC4J_AUTHORIZER_VERSION="v0.1.1"
RUN wget -P ${ZEPPELIN_HOME}/lib/ https://github.com/dsaidgovsg/pac4j-authorizer/releases/download/${PAC4J_AUTHORIZER_VERSION}/pac4j-authorizer_${SCALA_VERSION}-${PAC4J_AUTHORIZER_VERSION}.jar

RUN set -euo pipefail && \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.4.1/tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    tar xvf tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    mv tera-cli-v0.4.1-x86_64-unknown-linux-musl/tera /usr/local/bin/tera; \
    rm -rf tera-cli-v0.4.1-x86_64-unknown-linux-musl*; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN adduser --disabled-password --gecos "" zeppelin

ENV ZEPPELIN_IMPERSONATE_USER zeppelin
ENV ZEPPELIN_IMPERSONATE_CMD "gosu zeppelin bash -c "
ENV ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER false

# Entrypoint-ish env vars to apply config templates
ENV ZEPPELIN_APPLY_INTERPRETER_JSON "true"
ENV ZEPPELIN_APPLY_ZEPPELIN_SITE "true"
ENV ZEPPELIN_APPLY_SHIRO "true"

# Env var not expanded without Dockerfile, so need to go through sh
CMD ["bash", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
