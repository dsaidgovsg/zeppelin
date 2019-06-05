ARG SPARK_VERSION=2.4.0
FROM guangie88/spark-custom-addons:${SPARK_VERSION}_hadoop-3.1.0_hive_pyspark_alpine

ARG ZEPPELIN_VERSION=0.8.1
ENV ZEPPELIN_VERSION "${ZEPPELIN_VERSION}"

ARG OTHER_INTERPRETERS=

WORKDIR /zeppelin
RUN set -euo pipefail && \
    wget -O - https://archive.apache.org/dist/zeppelin/zeppelin-${ZEPPELIN_VERSION}/zeppelin-${ZEPPELIN_VERSION}-bin-netinst.tgz | \
        tar xz --strip-components=1 -C /zeppelin zeppelin-${ZEPPELIN_VERSION}-bin-netinst; \
    :

RUN set -euo pipefail && \
    wget http://central.maven.org/maven2/io/buji/buji-pac4j/4.1.0/buji-pac4j-4.1.0.jar; \
    wget http://central.maven.org/maven2/org/pac4j/pac4j-oauth/3.7.0/pac4j-oauth-3.7.0.jar; \
    wget http://central.maven.org/maven2/org/apache/shiro/shiro-web/1.4.1/shiro-web-1.4.1.jar; \
    wget http://central.maven.org/maven2/org/apache/shiro/shiro-core/1.4.1/shiro-core-1.4.1.jar; \
    :

RUN set -euo pipefail && \
    if [ ! -z "${OTHER_INTERPRETERS}" ]; then \
        ./bin/install-interpreter.sh --name "${OTHER_INTERPRETERS}"; \
    fi; \
    :

RUN set -euo pipefail && \
    mv /zeppelin/*.jar /zeppelin/lib/; \
    :

RUN apk add --no-cache su-exec krb5 && \
    ln -s /sbin/su-exec /usr/bin/gosu

RUN set -euo pipefail && \
    wget https://github.com/guangie88/tera-cli/releases/download/v0.1.1/tera_linux_amd64; \
    chmod +x tera_linux_amd64; \
    mv tera_linux_amd64 /usr/local/bin/tera; \
    :

RUN adduser -D zeppelin

ENV ZEPPELIN_IMPERSONATE_USER zeppelin
ENV ZEPPELIN_IMPERSONATE_CMD "gosu zeppelin bash -c "
ENV ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER false

ENV SPARK_JARS="/opt/spark/jars"
ENV SPARK_MASTER='local[*]'

RUN mkdir -p /zeppelin/notebook

# Install Zeppelin config
COPY docker /zeppelin
CMD ["/zeppelin/run-zeppelin.sh"]
