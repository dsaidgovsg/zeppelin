ARG FROM_DOCKER_IMAGE=
FROM ${FROM_DOCKER_IMAGE}

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

# Install JAR loader
ARG ZEPPELIN_JAR_LOADER_VERSION=v0.2.0
ENV ZEPPELIN_JAR_LOADER_VERSION "${ZEPPELIN_JAR_LOADER_VERSION}"
RUN wget -P ${SPARK_HOME}/jars/ https://github.com/datagovsg/zeppelin-jar-loader/releases/download/${ZEPPELIN_JAR_LOADER_VERSION}/zeppelin-jar-loader-${ZEPPELIN_JAR_LOADER_VERSION}.jar

# Install env domain authorizer
ARG PAC4J_AUTHORIZER_VERSION=v0.1.0
ENV PAC4J_AUTHORIZER_VERSION "${PAC4J_AUTHORIZER_VERSION}"
RUN wget -P ${ZEPPELIN_HOME}/lib/ https://github.com/datagovsg/pac4j-authorizer/releases/download/${PAC4J_AUTHORIZER_VERSION}/pac4j-authorizer-${PAC4J_AUTHORIZER_VERSION}.jar

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
