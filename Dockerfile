ARG SPARK_VERSION
ARG SCALA_VERSION
ARG HADOOP_VERSION
# Python version doesn't matter much for Zeppelin, so we just default to latest
ARG PYTHON_VERSION="3.7"
FROM guangie88/spark-custom-addons:${SPARK_VERSION}_scala-${SCALA_VERSION}_hadoop-${HADOOP_VERSION}_python-${PYTHON_VERSION}_hive_pyspark_alpine

WORKDIR /zeppelin
ENV ZEPPELIN_HOME "/zeppelin"
RUN mkdir -p "${ZEPPELIN_HOME}"

ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

ARG ZEPPELIN_VERSION
ENV ZEPPELIN_VERSION "${ZEPPELIN_VERSION}"

# Install Zeppelin from pre-built package
ARG ZEPPELIN_OTHER_INTERPRETERS=""

RUN set -euo pipefail && \
    wget -O - https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz | \
        tar xz --strip-components=1 -C ${ZEPPELIN_HOME} zeppelin-${ZEPPELIN_VERSION}-bin-netinst; \
    if [ ! -z "${ZEPPELIN_OTHER_INTERPRETERS}" ]; then \
        ./bin/install-interpreter.sh --name "${ZEPPELIN_OTHER_INTERPRETERS}"; \
    fi; \
    :

# Install JAR loader
ARG ZEPPELIN_JAR_LOADER_VERSION="v0.2.1"
ENV ZEPPELIN_JAR_LOADER_VERSION "${ZEPPELIN_JAR_LOADER_VERSION}"
ARG SCALA_VERSION

RUN set -euo pipefail && \
    wget -P ${SPARK_HOME}/jars/ https://github.com/dsaidgovsg/zeppelin-jar-loader/releases/download/${ZEPPELIN_JAR_LOADER_VERSION}/zeppelin-jar-loader_${SCALA_VERSION}-${ZEPPELIN_JAR_LOADER_VERSION}.jar; \
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

CMD ["${ZEPPELIN_HOME}/run-zeppelin.sh"]
