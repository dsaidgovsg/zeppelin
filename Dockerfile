ARG SPARK_VERSION=2.4.0
ARG HADOOP_VERSION=3.1.0
FROM guangie88/spark-custom-addons:${SPARK_VERSION}_hadoop-${HADOOP_VERSION}_hive_pyspark_alpine

WORKDIR /zeppelin
ENV ZEPPELIN_HOME "/zeppelin"
RUN mkdir -p "${ZEPPELIN_HOME}"

ENV ZEPPELIN_NOTEBOOK "/zeppelin/notebook"

ARG ZEPPELIN_VERSION=0.8.1
ENV ZEPPELIN_VERSION "${ZEPPELIN_VERSION}"

# Install Zeppelin from pre-built package
RUN wget -O - https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz | \
        tar xz --strip-components=1 -C ${ZEPPELIN_HOME} zeppelin-${ZEPPELIN_VERSION}-bin-netinst

ARG ZEPPELIN_OTHER_INTERPRETERS=
RUN if [ ! -z "${ZEPPELIN_OTHER_INTERPRETERS}" ]; then \
        ./bin/install-interpreter.sh --name "${ZEPPELIN_OTHER_INTERPRETERS}"; \
    fi

RUN set -euo pipefail && \
    # Install Shiro authorization related JARs
    wget -P ${ZEPPELIN_HOME}/lib/ http://central.maven.org/maven2/io/buji/buji-pac4j/4.0.0/buji-pac4j-4.0.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ http://central.maven.org/maven2/org/pac4j/pac4j-core/3.2.0/pac4j-core-3.2.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ http://central.maven.org/maven2/org/pac4j/pac4j-oauth/3.2.0/pac4j-oauth-3.2.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ http://central.maven.org/maven2/org/apache/shiro/shiro-web/1.4.0/shiro-web-1.4.0.jar; \
    wget -P ${ZEPPELIN_HOME}/lib/ http://central.maven.org/maven2/org/apache/shiro/shiro-core/1.4.0/shiro-core-1.4.0.jar; \
    # Install JAR loader
    wget -P ${SPARK_HOME}/jars/ https://github.com/datagovsg/zeppelin-jar-loader/releases/download/v0.1.0/zeppelin-jar-loader-v0.1.0.jar; \
    :

RUN set -euo pipefail && \
    # Install gosu for non-root execution
    apk add --no-cache su-exec; \
    ln -s /sbin/su-exec /usr/bin/gosu; \
    # Install tera-cli for runtime interpolation
    wget https://github.com/guangie88/tera-cli/releases/download/v0.1.1/tera_linux_amd64; \
    chmod +x tera_linux_amd64; \
    mv tera_linux_amd64 /usr/local/bin/tera; \
    :

COPY docker ${ZEPPELIN_HOME}

RUN adduser -D zeppelin

ENV ZEPPELIN_IMPERSONATE_USER zeppelin
ENV ZEPPELIN_IMPERSONATE_CMD "gosu zeppelin bash -c "
ENV ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER false

CMD ["sh", "-c", "${ZEPPELIN_HOME}/run-zeppelin.sh"]
