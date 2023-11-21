ARG SPARK_VERSION="3.4.1"
ARG HADOOP_VERSION="3.3.4"
ARG SCALA_VERSION="2.12"
ARG JAVA_VERSION="8"

# Python version doesn't matter much for Zeppelin, so we just default to the latest 3.9
FROM dsaidgovsg/spark-k8s-addons:v5_${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_scala-${SCALA_VERSION}_java-${JAVA_VERSION}_python-3.9
USER root

ENV ZEPPELIN_HOME "/zeppelin"

WORKDIR /zeppelin
ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

# Install required apt packages
RUN set -euo pipefail && \
    apt-get update && apt-get install -y --no-install-recommends \
        fuse \
        gosu \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/*; \
    :

# Install Zeppelin binary
ARG ZEPPELIN_VERSION="0.10.1"
RUN set -euo pipefail && \
    wget https://dlcdn.apache.org/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz; \
    tar xvf zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz --strip-components=1; \
    rm zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz; \
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

# `buji-pac4j-4.1.1.jar` is the last tested working jar for Zeppelin (every version after this redirects to /null for OAuth2.0 some reason)
# Install `buji-pac4j` and `pac4j-oauth` to support OIDC / OAuth2.0 login
# We do not add / change shiro-* jars because the Zeppelin >= 0.10.1 uses shiro-* 1.7.0, which is sufficient for the above two dependencies
RUN set -euo pipefail && \
    wget -P ${ZEPPELIN_HOME}/lib/ https://repo1.maven.org/maven2/io/buji/buji-pac4j/4.1.1/buji-pac4j-4.1.1.jar; \
    # https://github.com/bujiio/buji-pac4j/blob/buji-pac4j-4.1.1/pom.xml#L86:
    # pac4j stated to be 3.7.0, but 3.9.0 is tested to work
    wget -P ${ZEPPELIN_HOME}/lib/ https://repo1.maven.org/maven2/org/pac4j/pac4j-core/3.9.0/pac4j-core-3.9.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ https://repo1.maven.org/maven2/org/pac4j/pac4j-oauth/3.9.0/pac4j-oauth-3.9.0.jar; \
    # https://github.com/pac4j/pac4j/blob/pac4j-3.9.0/pac4j-oauth/pom.xml#L16:
    # scribejava stated to be 5.6.0, and we follow
    wget -P ${ZEPPELIN_HOME}/lib/ https://repo1.maven.org/maven2/com/github/scribejava/scribejava-apis/5.6.0/scribejava-apis-5.6.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ https://repo1.maven.org/maven2/com/github/scribejava/scribejava-core/5.6.0/scribejava-core-5.6.0.jar; \
    :

RUN set -euo pipefail && \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.4.1/tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    tar xvf tera-cli-v0.4.1-x86_64-unknown-linux-musl.tar.gz; \
    mv tera-cli-v0.4.1-x86_64-unknown-linux-musl/tera /usr/local/bin/tera; \
    rm -rf tera-cli-v0.4.1-x86_64-unknown-linux-musl*; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN set -euo pipefail && \
    adduser --disabled-password --gecos "" zeppelin; \
    chown -R zeppelin:zeppelin "${ZEPPELIN_HOME}"; \
    :

USER zeppelin

# Entrypoint-ish env vars to apply config templates
ENV ZEPPELIN_APPLY_INTERPRETER_JSON "true"
ENV ZEPPELIN_APPLY_ZEPPELIN_SITE "true"
ENV ZEPPELIN_APPLY_SHIRO "true"

# Env var not expanded without Dockerfile, so need to go through sh
CMD ["bash", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
