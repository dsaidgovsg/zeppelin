# Version changes

The changes here are cumulative from oldest to latest version.

In principle, new features can be added to an existing version, but the change
should not be breaking to existing default `docker run` with default env vars
set-up.

## v5
- No longer use fat jar from <https://github.com/dsaidgovsg/pac4j-authorizer>,
  and instead place the latest working `buji-pac4j` and `pac4j-oauth` (and
  their deps JARs) into `${ZEPPELIN_HOME}/lib`.
- Replaced `log4j-1.2.17.jar` and `slf4j-log4j12-1.7.30` with reload4j variant.

## v4
- No longer self-compilation of Zeppelin from source code since it hardly works,
  using pre-built binary `zeppelin-x.y.z-bin-netinst.tgz`.
- Drop all `_IMPERSONATE_` env vars since they do not work properly in Zeppelin
  0.10.z:
  - `ZEPPELIN_IMPERSONATE_USER`
  - `ZEPPELIN_IMPERSONATE_CMD`
  - `ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER`
- Drop minor.patch versions in self-version.

## v3.0.0

- Change default behaviour of not supplying the following Spark env vars (all of
  them from previous version). No values will be used instead, leaving it to use
  `spark-defaults.conf` if you have.
  - `SPARK_MASTER`
  - `SPARK_JARS`
  - `SPARK_SUBMIT_DEPLOYMODE`
  - `SPARK_APP_NAME`
  - `SPARK_ARGS`
  - `SPARK_EXECUTOR_MEMORY`
  - `SPARK_EVENTLOG_ENABLED`
  - `SPARK_EVENTLOG_DIR`
  - `SPARK_CORES_MAX`
  - `SPARK_SHUFFLE_SERVICE_ENABLED`
  - `SPARK_DYNAMICALLOCATION_ENABLED`
  - `SPARK_DYNAMICALLOCATION_MAXEXECUTORS`
  - `SPARK_DYNAMICALLOCATION_CACHEDEXECUTORIDLETIMEOUT`
- Change the following env var names:
  - `SPARK_INTERPRETER_PER_NOTE` to `ZEPPELIN_SPARK_INTERPRETER_PER_NOTE`
  - `SPARK_INTERPRETER_PER_USER` to `ZEPPELIN_SPARK_INTERPRETER_PER_USER`

## v2.1.0

- Allow application of existing template to be optional:
  - `ZEPPELIN_APPLY_INTERPRETER_JSON`, set to `false` to disable
    applying `interpreter.json.template`.
  - `ZEPPELIN_APPLY_ZEPPELIN_SITE`, set to `false` to disable applying
    `zeppelin-site.xml.template`.
  - `ZEPPELIN_APPLY_SHIRO`, set to `false` to disable applying
    `shiro.ini.template`.

## v2.0.0

- Use Kubernetes supported Spark image.
- Change from Alpine to Debian because of Kubernetes support.
- Drops `zeppelin-jar-loader`.

## v1

This assumes that the default command is used. The default port that Zeppelin
uses is `8080`. To change it, override the env var `ZEPPELIN_PORT` to any other
port value.

- Env vars
  - General
    - `ZEPPELIN_HOME="/zeppelin"`
    - `ZEPPELIN_NOTEBOOK="/zeppelin/notebook"`
    - `ZEPPELIN_IMPERSONATE_USER="zeppelin"`
    - `ZEPPELIN_IMPERSONATE_CMD="gosu zeppelin bash -c "`
    - `ZEPPELIN_IMPERSONATE_SPARK_PROXY_USER="false"`
  - `interpreter.json.template`
    Too many to list, all Spark interpreter related options do have
    corresponding env vars to control the value. E.g.:
    - `SPARK_MASTER`
    - `SPARK_JARS`
    - `ZEPPELIN_SPARK_ENABLESUPPORTEDVERSIONCHECK`, etc.
  - `zeppelin-site.xml.template
    - `SERVER_ADDR="0.0.0.0"`
    - `ZEPPELIN_PORT="8080"`
    - `ZEPPELIN_SSL_PORT="8080"`
    - `ZEPPELIN_NOTEBOOK` notebook dir location as stated in `General`

- Others
  - `zeppelin-jar-loader v0.2.1"` (only for Zeppelin `0.8.1` and below) and
    `pac4j-authorizer v0.1.1` JARs are present for use as described in
    [`README.md`](README.md).
  - `ghafs v0.1.2` executable is present in `PATH`, check
    <https://github.com/guangie88/ghafs> for more details.
